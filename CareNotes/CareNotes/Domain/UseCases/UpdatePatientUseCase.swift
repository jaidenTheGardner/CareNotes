//
//  UpdatePatientUseCase.swift
//  CareNotes
//
//  Created by Neha on 22/10/2026.
//
//
//  UpdatePatientUseCase.swift
//  CareNotes
//

// Updates an existing patient's name and date of birth.

// Business Rule: Edited details follow the same rules as registration
// (a valid name; an optional, valid date of birth). The patient's
// identity and registration date never change.

import Foundation

nonisolated struct UpdatePatientUseCase: Sendable {
    struct Request: Sendable {
        var patientID: Patient.ID
        var name: String
        var dateOfBirth: Date?
        init(patientID: Patient.ID, name: String, dateOfBirth: Date? = nil) {
            self.patientID = patientID
            self.name = name
            self.dateOfBirth = dateOfBirth
        }
    }

    private let patients: any PatientRepository
    private let dates: any DateProviding
    private let calendar: Calendar

    init(patients: any PatientRepository,
         dates: any DateProviding = SystemDateProvider(),
         calendar: Calendar = .current) {
        self.patients = patients
        self.dates = dates
        self.calendar = calendar
    }

    func execute(_ request: Request) async throws -> Patient {
        let found = try await guardingStorage { try await patients.patient(withID: request.patientID) }
        guard var patient = found else { throw DomainError.patientNotFound(request.patientID) }

        let now = dates.now()
        patient.name = try validating { try PersonName(request.name) }
        patient.birthDate = try validating {
            try request.dateOfBirth.map { try BirthDate($0, asOf: now, calendar: calendar) }
        }
        try await guardingStorage { try await patients.save(patient) }
        return patient
    }
}
