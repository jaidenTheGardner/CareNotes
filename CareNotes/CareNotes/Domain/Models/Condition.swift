//
//  Condition.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated enum ConditionStatus: Hashable, Sendable {
    case active
    case resolved(on: Date)
}

nonisolated struct Condition: Identifiable, Hashable, Sendable {
    typealias ID = EntityID<Condition>

    let id: ID
    let patientID: Patient.ID
    var name: ConditionName
    let onsetDate: Date
    private(set) var status: ConditionStatus
    let createdAt: Date

    init(id: ID = ID(),
         patientID: Patient.ID,
         name: ConditionName,
         onsetDate: Date,
         status: ConditionStatus = .active,
         createdAt: Date) {
        self.id = id
        self.patientID = patientID
        self.name = name
        self.onsetDate = onsetDate
        self.status = status
        self.createdAt = createdAt
    }

    var isActive: Bool {
        if case .active = status { return true }
        return false
    }

    var resolvedDate: Date? {
        if case .resolved(let date) = status { return date }
        return nil
    }

    /// Invariants live on the entity so no caller can bypass them.
    mutating func resolve(on date: Date) throws {
        guard isActive else { throw DomainError.conditionAlreadyResolved(id) }
        guard date >= onsetDate else { throw DomainError.resolutionPredatesOnset(id) }
        status = .resolved(on: date)
    }
}
