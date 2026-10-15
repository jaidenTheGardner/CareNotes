//
//  ValidationError.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated enum ValidationField: String, Sendable {
    case patientName, conditionName, clinicalNote
    case severityScore, dateOfBirth, onsetDate, recordedAt, resolvedOn, trendWindow
}

nonisolated enum ValidationError: Error, Equatable, Sendable {
    case empty(ValidationField)
    case tooLong(ValidationField, maxLength: Int)
    case outOfRange(ValidationField, allowed: ClosedRange<Int>)
    case dateInFuture(ValidationField)
    case dateImplausible(ValidationField)
}
