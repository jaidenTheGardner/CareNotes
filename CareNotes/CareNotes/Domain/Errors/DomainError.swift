//
//  DomainError.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated struct StorageFailure: Equatable, Sendable {
    let message: String
    init(_ error: Error) { message = error.localizedDescription }
}

nonisolated enum DomainError: Error, Equatable, Sendable {
    case validation(ValidationError)
    case patientNotFound(Patient.ID)
    case conditionNotFound(Condition.ID)
    case duplicateActiveCondition(ConditionName)
    case conditionAlreadyResolved(Condition.ID)
    case resolutionPredatesOnset(Condition.ID)
    case entryDatedInFuture
    case entryPredatesOnset
    case insufficientData(required: Int, available: Int)
    case storage(StorageFailure)
}

extension DomainError: LocalizedError {
    nonisolated var errorDescription: String? {
        switch self {
        case .validation(let v):
            return v.userMessage
        case .patientNotFound:
            return String(localized: "That patient could not be found.")
        case .conditionNotFound:
            return String(localized: "That condition could not be found.")
        case .duplicateActiveCondition(let name):
            return String(localized: "“\(name.value)” is already being tracked for this patient.")
        case .conditionAlreadyResolved:
            return String(localized: "This condition is already marked as resolved.")
        case .resolutionPredatesOnset:
            return String(localized: "A condition can't be resolved before it began.")
        case .entryDatedInFuture:
            return String(localized: "An entry can't be recorded in the future.")
        case .entryPredatesOnset:
            return String(localized: "An entry can't be recorded before the condition began.")
        case .insufficientData(let required, let available):
            return String(localized: "At least \(required) entries are needed to show a trend (found \(available)).")
        case .storage:
            return String(localized: "Your notes couldn't be saved or loaded. Please try again.")
        }
    }
}

extension ValidationError {
    nonisolated var userMessage: String {
        switch self {
        case .empty:
            return String(localized: "This field can't be empty.")
        case .tooLong(_, let max):
            return String(localized: "This is too long (maximum \(max) characters).")
        case .outOfRange(_, let allowed):
            return String(localized: "Choose a value from \(allowed.lowerBound) to \(allowed.upperBound).")
        case .dateInFuture:
            return String(localized: "This date can't be in the future.")
        case .dateImplausible:
            return String(localized: "That date doesn't look right.")
        }
    }
}

// MARK: - Boundary helpers

/// Runs value-object construction and converts `ValidationError` into `DomainError`.
nonisolated func validating<T>(_ build: () throws -> T) throws -> T {
    do { return try build() }
    catch let error as ValidationError { throw DomainError.validation(error) }
}

/// Runs repository work and converts any non-domain error into `DomainError.storage`.
nonisolated func guardingStorage<T>(_ work: () async throws -> T) async throws -> T {
    do { return try await work() }
    catch let error as DomainError { throw error }
    catch { throw DomainError.storage(StorageFailure(error)) }
}
