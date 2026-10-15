//
//  PatientDetailViewModel.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation
import Observation

@Observable
final class PatientDetailViewModel {
    private let environment: AppEnvironment
    let patient: Patient

    var conditions: [Condition] = []
    var latestEntries: [Condition.ID: SeverityEntry] = [:]
    var errorMessage: String?

    init(environment: AppEnvironment, patient: Patient) {
        self.environment = environment
        self.patient = patient
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
