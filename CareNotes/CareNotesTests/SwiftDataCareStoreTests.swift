//
//  SwiftDataCareStoreTests.swift
//  CareNotesTests
//

// Verifies the SwiftData repositories store, filter and map data
// correctly, and that storage failures reach the user as domain errors.

import XCTest
import SwiftData
@testable import CareNotes

final class SwiftDataCareStoreTests: XCTestCase {

    // MARK: - Fixtures

    private func makeStore() throws -> SwiftDataCareStore {
        SwiftDataCareStore(modelContainer: try CareNotesPersistence.makeContainer(inMemory: true))
    }

    private func makePatient(_ name: String = "Alex Chen") throws -> Patient {
        Patient(name: try PersonName(name), registeredAt: Date())
    }

    private func makeCondition(for patient: Patient, name: String = "Migraine", daysAgo: Int = 30) throws -> Condition {
        Condition(patientID: patient.id,
                  name: try ConditionName(name),
                  onsetDate: Date().addingTimeInterval(-Double(daysAgo) * 86_400),
                  createdAt: Date())
    }

    private func daysAgo(_ days: Double) -> Date {
        Date().addingTimeInterval(-days * 86_400)
    }

    // MARK: - Tests

    func testPatientRoundTripsThroughStore() async throws {
        let store = try makeStore()
        let birth = try BirthDate(daysAgo(365 * 40), asOf: Date())
        let patient = Patient(name: try PersonName("  Alex   Chen "), birthDate: birth, registeredAt: Date())

        try await store.save(patient)
        let loaded = try await store.patient(withID: patient.id)

        XCTAssertEqual(loaded, patient)
        XCTAssertEqual(loaded?.name.value, "Alex Chen")
    }

    func testDataSurvivesReopeningTheStoreFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("store")
        let patient = try makePatient()

        let firstLaunch = SwiftDataCareStore(modelContainer: try CareNotesPersistence.makeContainer(storeURL: url))
        try await firstLaunch.save(patient)

        let secondLaunch = SwiftDataCareStore(modelContainer: try CareNotesPersistence.makeContainer(storeURL: url))
        let loaded = try await secondLaunch.allPatients()

        XCTAssertEqual(loaded.map(\.id), [patient.id])
    }

    func testSavingConditionForUnknownPatientThrowsPatientNotFound() async throws {
        let store = try makeStore()
        let orphan = try makeCondition(for: try makePatient())   // patient never saved

        do {
            try await store.save(orphan)
            XCTFail("Expected patientNotFound")
        } catch let error as DomainError {
            XCTAssertEqual(error, .patientNotFound(orphan.patientID))
        }
    }

    func testResolvedStatusIsPersisted() async throws {
        let store = try makeStore()
        let patient = try makePatient()
        var condition = try makeCondition(for: patient)
        try await store.save(patient)
        try await store.save(condition)

        let resolvedOn = daysAgo(1)
        try condition.resolve(on: resolvedOn)
        try await store.save(condition)

        let loaded = try await store.condition(withID: condition.id)
        XCTAssertEqual(loaded?.resolvedDate, resolvedOn)
        XCTAssertEqual(loaded?.isActive, false)
    }

    func testConditionQueryFiltersByPatientAndStatus() async throws {
        let store = try makeStore()
        let alex = try makePatient("Alex Chen")
        let sam = try makePatient("Sam Patel")
        let migraine = try makeCondition(for: alex, name: "Migraine")
        var backPain = try makeCondition(for: alex, name: "Back pain")
        let asthma = try makeCondition(for: sam, name: "Asthma")
        try backPain.resolve(on: Date())
        for patient in [alex, sam] { try await store.save(patient) }
        for condition in [migraine, backPain, asthma] { try await store.save(condition) }

        let alexActive = try await store.conditions(matching: ConditionQuery(patientID: alex.id, status: .active))

        XCTAssertEqual(alexActive.map(\.id), [migraine.id])
    }

    func testEntryQueryAppliesWindowOrderLimitAndBand() async throws {
        let store = try makeStore()
        let patient = try makePatient()
        let condition = try makeCondition(for: patient, daysAgo: 30)
        try await store.save(patient)
        try await store.save(condition)
        for (score, age) in [(2, 20.0), (5, 10.0), (7, 5.0), (4, 1.0)] {
            try await store.save(SeverityEntry(conditionID: condition.id,
                                               score: try SeverityScore(score),
                                               recordedAt: daysAgo(age)))
        }
        let lastTwelveDays = daysAgo(12)...Date()

        let latestTwo = try await store.entries(matching: SeverityEntryQuery(conditionID: condition.id,
                                                                             recordedWithin: lastTwelveDays,
                                                                             order: .newestFirst,
                                                                             limit: 2))
        let severeOnly = try await store.entries(matching: SeverityEntryQuery(conditionID: condition.id,
                                                                              recordedWithin: lastTwelveDays,
                                                                              minimumBand: .severe))

        XCTAssertEqual(latestTwo.map(\.score.value), [4, 7])
        XCTAssertEqual(severeOnly.map(\.score.value), [7])
    }

    func testRegisterPatientMapsRepositoryFailureToStorageError() async throws {
        let useCase = RegisterPatientUseCase(patients: FailingPatientRepository())

        do {
            _ = try await useCase.execute(.init(name: "Alex Chen"))
            XCTFail("Expected a storage error")
        } catch DomainError.storage(_) {
            // Expected: the raw database error is hidden behind a domain error.
        }
    }
}

// MARK: - Mocks

/// Simulates a database that fails on every call (e.g. disk full).
private struct FailingPatientRepository: PatientRepository {
    struct DiskFull: Error {}
    func patient(withID id: Patient.ID) async throws -> Patient? { throw DiskFull() }
    func allPatients() async throws -> [Patient] { throw DiskFull() }
    func save(_ patient: Patient) async throws { throw DiskFull() }
    func delete(_ id: Patient.ID) async throws { throw DiskFull() }
}
