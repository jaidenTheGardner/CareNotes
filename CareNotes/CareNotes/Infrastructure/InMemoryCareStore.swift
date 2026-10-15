//
//  InMemoryCareStore.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// TEMPORARY in-memory storage for patients, conditions and entries
// until persistence capabilities are added

import Foundation

actor InMemoryCareStore: PatientRepository, ConditionRepository, SeverityEntryRepository {
    private var patientsByID: [Patient.ID: Patient] = [:]
    private var conditionsByID: [Condition.ID: Condition] = [:]
    private var entriesByID: [SeverityEntry.ID: SeverityEntry] = [:]

    // PatientRepository
    func patient(withID id: Patient.ID) async throws -> Patient? { patientsByID[id] }
    func allPatients() async throws -> [Patient] {
        patientsByID.values.sorted { $0.registeredAt < $1.registeredAt }
    }
    func save(_ patient: Patient) async throws { patientsByID[patient.id] = patient }

    // ConditionRepository
    func condition(withID id: Condition.ID) async throws -> Condition? { conditionsByID[id] }
    func conditions(matching query: ConditionQuery) async throws -> [Condition] {
        conditionsByID.values.filter(query.matches).sorted { $0.createdAt < $1.createdAt }
    }
    func save(_ condition: Condition) async throws { conditionsByID[condition.id] = condition }

    // SeverityEntryRepository
    func entries(matching query: SeverityEntryQuery) async throws -> [SeverityEntry] {
        query.apply(to: Array(entriesByID.values))
    }
    func save(_ entry: SeverityEntry) async throws { entriesByID[entry.id] = entry }
}
