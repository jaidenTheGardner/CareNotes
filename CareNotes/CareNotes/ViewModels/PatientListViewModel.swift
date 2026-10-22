//
//  PatientListViewModel.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation
import Observation

@Observable
final class PatientListViewModel {
    private let environment: AppEnvironment

    var patients: [Patient] = []
    var isLoading = false
    var errorMessage: String?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            patients = try await environment.loadPatients.execute()
            CareNotesWidgetPublisher.publish(patientCount: patients.count)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
