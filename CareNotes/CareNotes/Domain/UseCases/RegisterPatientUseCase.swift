//
//  RegisterPatientUseCase.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated struct RegisterPatientUseCase: Sendable {
    struct Request: Sendable {
        var name: String
        var dateOfBirth: Date?
        init(name: String, dateOfBirth: Date? = nil) {
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
        let now = dates.now()
        let name = try validating { try PersonName(request.name) }
        let birthDate = try validating {
            try request.dateOfBirth.map { try BirthDate($0, asOf: now, calendar: calendar) }
        }
        let patient = Patient(name: name, birthDate: birthDate, registeredAt: now)
        try await guardingStorage { try await patients.save(patient) }
        return patient
    }
}
