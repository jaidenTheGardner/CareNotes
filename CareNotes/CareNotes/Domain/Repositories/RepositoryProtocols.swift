//
//  RepositoryProtocols.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated protocol PatientRepository: Sendable {
    func patient(withID id: Patient.ID) async throws -> Patient?
    func allPatients() async throws -> [Patient]
    func save(_ patient: Patient) async throws
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
