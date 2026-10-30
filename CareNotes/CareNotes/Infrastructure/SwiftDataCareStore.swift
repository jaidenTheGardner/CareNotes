//
//  SwiftDataCareStore.swift
//  CareNotes
//

// On-device SwiftData implementation of the patient, condition and
// severity entry repositories. Runs on its own background actor so
// database work never blocks the UI.

// Business Rule: This store filters and sorts exactly like the domain
// query reference (`ConditionQuery.matches`, `SeverityEntryQuery.apply`),
// so swapping storage never changes what the user sees.

import Foundation
import SwiftData

actor SwiftDataCareStore: ModelActor, PatientRepository, ConditionRepository, SeverityEntryRepository {
    // Written out by hand instead of using the @ModelActor macro: the macro's
    // generated init isn't visible to the test target in this project.
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
        self.modelContainer = modelContainer
    }

    // MARK: - PatientRepository

    func patient(withID id: Patient.ID) async throws -> Patient? {
        try patientRecord(id.rawValue)?.toDomain()
    }

    func allPatients() async throws -> [Patient] {
        let descriptor = FetchDescriptor<PatientRecord>(sortBy: [SortDescriptor(\.registeredAt)])
        return try modelContext.fetch(descriptor).map { try $0.toDomain() }
    }

    func save(_ patient: Patient) async throws {
        if let record = try patientRecord(patient.id.rawValue) {
            record.name = patient.name.value
            record.birthDate = patient.birthDate?.value
        } else {
            modelContext.insert(PatientRecord(id: patient.id.rawValue,
                                              name: patient.name.value,
                                              birthDate: patient.birthDate?.value,
                                              registeredAt: patient.registeredAt))
        }
        try commit()
    }

    func delete(_ id: Patient.ID) async throws {
        guard let record = try patientRecord(id.rawValue) else { return }
        // Cascade rules on the relationships remove the patient's conditions and entries.
        modelContext.delete(record)
        try commit()
    }
    
    // MARK: - ConditionRepository

    func condition(withID id: Condition.ID) async throws -> Condition? {
        try conditionRecord(id.rawValue)?.toDomain()
    }

    func conditions(matching query: ConditionQuery) async throws -> [Condition] {
        var descriptor = FetchDescriptor<ConditionRecord>(sortBy: [SortDescriptor(\.createdAt)])
        if let patientID = query.patientID?.rawValue {
            descriptor.predicate = #Predicate { $0.patient?.id == patientID }
        }
        // Status and name rules come from the shared domain query.
        return try modelContext.fetch(descriptor)
            .map { try $0.toDomain() }
            .filter(query.matches)
    }

    func save(_ condition: Condition) async throws {
        if let record = try conditionRecord(condition.id.rawValue) {
            record.name = condition.name.value
            record.resolvedAt = condition.resolvedDate
        } else {
            guard let patient = try patientRecord(condition.patientID.rawValue) else {
                throw DomainError.patientNotFound(condition.patientID)
            }
            let record = ConditionRecord(id: condition.id.rawValue,
                                         name: condition.name.value,
                                         onsetDate: condition.onsetDate,
                                         resolvedAt: condition.resolvedDate,
                                         createdAt: condition.createdAt)
            modelContext.insert(record)
            record.patient = patient
        }
        try commit()
    }

    // MARK: - SeverityEntryRepository

    func entries(matching query: SeverityEntryQuery) async throws -> [SeverityEntry] {
        let lower = query.recordedWithin?.lowerBound ?? .distantPast
        let upper = query.recordedWithin?.upperBound ?? .distantFuture
        let order: SortOrder = query.order == .newestFirst ? .reverse : .forward

        var descriptor = FetchDescriptor<SeverityEntryRecord>(sortBy: [SortDescriptor(\.recordedAt, order: order)])
        if let conditionID = query.conditionID?.rawValue {
            descriptor.predicate = #Predicate {
                $0.condition?.id == conditionID && $0.recordedAt >= lower && $0.recordedAt <= upper
            }
        } else {
            descriptor.predicate = #Predicate { $0.recordedAt >= lower && $0.recordedAt <= upper }
        }
        // The limit can only be pushed to the database when nothing is filtered afterwards.
        if query.minimumBand == nil, let limit = query.limit, limit >= 0 {
            descriptor.fetchLimit = limit
        }
        return query.apply(to: try modelContext.fetch(descriptor).map { try $0.toDomain() })
    }

    func save(_ entry: SeverityEntry) async throws {
        if let record = try entryRecord(entry.id.rawValue) {
            record.note = entry.note?.value
        } else {
            guard let condition = try conditionRecord(entry.conditionID.rawValue) else {
                throw DomainError.conditionNotFound(entry.conditionID)
            }
            let record = SeverityEntryRecord(id: entry.id.rawValue,
                                             score: entry.score.value,
                                             recordedAt: entry.recordedAt,
                                             note: entry.note?.value)
            modelContext.insert(record)
            record.condition = condition
        }
        try commit()
    }

    // MARK: - Helpers

    private func patientRecord(_ recordID: UUID) throws -> PatientRecord? {
        var descriptor = FetchDescriptor<PatientRecord>(predicate: #Predicate { $0.id == recordID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func conditionRecord(_ recordID: UUID) throws -> ConditionRecord? {
        var descriptor = FetchDescriptor<ConditionRecord>(predicate: #Predicate { $0.id == recordID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func entryRecord(_ recordID: UUID) throws -> SeverityEntryRecord? {
        var descriptor = FetchDescriptor<SeverityEntryRecord>(predicate: #Predicate { $0.id == recordID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Saves, or rolls back so a failed write never leaves half-applied changes behind.
    private func commit() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
