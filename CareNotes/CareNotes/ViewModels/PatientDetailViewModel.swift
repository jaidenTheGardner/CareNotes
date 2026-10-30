//
//  PatientDetailViewModel.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Holds the selected condition and the data

import Foundation
import Observation

@Observable
final class PatientDetailViewModel {
    private let environment: AppEnvironment
    private(set) var patient: Patient
    var conditions: [Condition] = []
    var latestEntries: [Condition.ID: SeverityEntry] = [:]
    var errorMessage: String?

    init(environment: AppEnvironment, patient: Patient) {
        self.environment = environment
        self.patient = patient
    }

    /// Re-reads the patient after an edit so the title and details stay current.
    func reloadPatient() async {
        do {
            let all = try await environment.loadPatients.execute()
            if let fresh = all.first(where: { $0.id == patient.id }) { patient = fresh }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Returns true when the patient was deleted, so the screen can close.
    func delete() async -> Bool {
        do {
            try await environment.deletePatient.execute(patientID: patient.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    var activeConditions: [Condition] { conditions.filter(\.isActive) }
    var resolvedConditions: [Condition] { conditions.filter { !$0.isActive } }

    func load() async {
        do {
            let list = try await environment.loadConditions.execute(patientID: patient.id)
            var latest: [Condition.ID: SeverityEntry] = [:]
            for condition in list {
                let newest = try await environment.loadEntries.execute(conditionID: condition.id, limit: 1)
                latest[condition.id] = newest.first
            }
            conditions = list
            latestEntries = latest
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
