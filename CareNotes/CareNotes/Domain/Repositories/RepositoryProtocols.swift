//
//  RepositoryProtocols.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Defines the storage contracts for patients, conditions and
// severity entries.

// Business Rule: Business rules don't depend on a particular
// database, so storage can be swapped without changing rules.

import Foundation

nonisolated protocol PatientRepository: Sendable {
    func patient(withID id: Patient.ID) async throws -> Patient?
    func allPatients() async throws -> [Patient]
    func save(_ patient: Patient) async throws
    func delete(_ id: Patient.ID) async throws
}
nonisolated protocol ConditionRepository: Sendable {
    func condition(withID id: Condition.ID) async throws -> Condition?
    func conditions(matching query: ConditionQuery) async throws -> [Condition]
    func save(_ condition: Condition) async throws
}

nonisolated protocol SeverityEntryRepository: Sendable {
    func entries(matching query: SeverityEntryQuery) async throws -> [SeverityEntry]
    func save(_ entry: SeverityEntry) async throws
}
