//
//  RecordConditionUseCase.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated struct RecordConditionUseCase: Sendable {
    struct Request: Sendable {
        var patientID: Patient.ID
        var name: String
        var onsetDate: Date
    }

    private let patients: any PatientRepository
    private let conditions: any ConditionRepository
    private let dates: any DateProviding
    private let calendar: Calendar

    init(patients: any PatientRepository,
         conditions: any ConditionRepository,
         dates: any DateProviding = SystemDateProvider(),
         calendar: Calendar = .current) {
        self.patients = patients
        self.conditions = conditions
        self.dates = dates
        self.calendar = calendar
    }

    func execute(_ request: Request) async throws -> Condition {
        let now = dates.now()
        let name = try validating { try ConditionName(request.name) }
        guard request.onsetDate <= now else {
            throw DomainError.validation(.dateInFuture(.onsetDate))
        }

        let patient = try await guardingStorage { try await patients.patient(withID: request.patientID) }
        guard patient != nil else { throw DomainError.patientNotFound(request.patientID) }

        let active = try await guardingStorage {
            try await conditions.conditions(matching: ConditionQuery(patientID: request.patientID, status: .active))
        }
        if active.contains(where: { $0.name.matchKey == name.matchKey }) {
            throw DomainError.duplicateActiveCondition(name)
        }

        let condition = Condition(patientID: request.patientID,
                                  name: name,
                                  onsetDate: calendar.startOfDay(for: request.onsetDate),
                                  createdAt: now)
        try await guardingStorage { try await conditions.save(condition) }
        return condition
    }
}
