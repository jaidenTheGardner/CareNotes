//
//  DeletePatientUseCase.swift
//  CareNotes
//
//  Created by Neha on 22/10/2026.
//

//
//  DeletePatientUseCase.swift
//  CareNotes
//

// Permanently deletes a patient together with all of their
// conditions and severity entries.

// Business Rule: A patient's health history belongs to that patient,
// so deleting the patient deletes everything recorded for them.
// Deleting a patient that no longer exists is reported, not ignored.

import Foundation

nonisolated struct DeletePatientUseCase: Sendable {
    private let patients: any PatientRepository

    init(patients: any PatientRepository) {
        self.patients = patients
    }

    func execute(patientID: Patient.ID) async throws {
        let found = try await guardingStorage { try await patients.patient(withID: patientID) }
        guard found != nil else { throw DomainError.patientNotFound(patientID) }
        try await guardingStorage { try await patients.delete(patientID) }
    }
}
