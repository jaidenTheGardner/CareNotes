//
//  LoadUseCases.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Provides read-only operations that fetch patients, conditions
// and severity entries for display.

// Business Rule: Active conditions are listed before resolved ones,
// and severity entries are listed newest first.

import Foundation

nonisolated struct LoadPatientsUseCase: Sendable {
    private let patients: any PatientRepository
    init(patients: any PatientRepository) { self.patients = patients }

    func execute() async throws -> [Patient] {
        try await guardingStorage { try await patients.allPatients() }
    }
}

nonisolated struct LoadConditionsUseCase: Sendable {
    private let conditions: any ConditionRepository
    init(conditions: any ConditionRepository) { self.conditions = conditions }

    /// Active conditions first, then resolved, each oldest-first.
    func execute(patientID: Patient.ID) async throws -> [Condition] {
        let all = try await guardingStorage {
            try await conditions.conditions(matching: ConditionQuery(patientID: patientID))
        }
        return all.filter(\.isActive) + all.filter { !$0.isActive }
    }
}

nonisolated struct LoadEntriesUseCase: Sendable {
    private let entries: any SeverityEntryRepository
    init(entries: any SeverityEntryRepository) { self.entries = entries }

    /// Newest first.
    func execute(conditionID: Condition.ID, limit: Int? = nil) async throws -> [SeverityEntry] {
        try await guardingStorage {
            try await entries.entries(matching: SeverityEntryQuery(conditionID: conditionID,
                                                                   order: .newestFirst,
                                                                   limit: limit))
        }
    }
}
