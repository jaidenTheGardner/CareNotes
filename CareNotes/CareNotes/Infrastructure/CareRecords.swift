//
//  CareRecords.swift
//  CareNotes
//

// SwiftData storage records for patients, conditions and severity
// entries, plus their conversion back into validated domain models.

// Business Rule: Records never reach the screens. Every record is
// re-validated into a domain model at the repository boundary, so
// damaged stored data surfaces as a storage error, not bad UI.

import Foundation
import SwiftData

// MARK: - Records

@Model
nonisolated final class PatientRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date?
    var registeredAt: Date

    /// Deleting a patient deletes their conditions (and, through them, entries).
    @Relationship(deleteRule: .cascade, inverse: \ConditionRecord.patient)
    var conditions: [ConditionRecord] = []

    init(id: UUID, name: String, birthDate: Date?, registeredAt: Date) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.registeredAt = registeredAt
    }
}

@Model
nonisolated final class ConditionRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var onsetDate: Date
    /// nil while the condition is active.
    var resolvedAt: Date?
    var createdAt: Date
    var patient: PatientRecord?

    @Relationship(deleteRule: .cascade, inverse: \SeverityEntryRecord.condition)
    var entries: [SeverityEntryRecord] = []

    init(id: UUID, name: String, onsetDate: Date, resolvedAt: Date?, createdAt: Date) {
        self.id = id
        self.name = name
        self.onsetDate = onsetDate
        self.resolvedAt = resolvedAt
        self.createdAt = createdAt
    }
}

@Model
nonisolated final class SeverityEntryRecord {
    // Trend and history screens always filter and sort by date.
    #Index<SeverityEntryRecord>([\.recordedAt])

    @Attribute(.unique) var id: UUID
    var score: Int
    var recordedAt: Date
    var note: String?
    var condition: ConditionRecord?

    init(id: UUID, score: Int, recordedAt: Date, note: String?) {
        self.id = id
        self.score = score
        self.recordedAt = recordedAt
        self.note = note
    }
}

// MARK: - Record → Domain

/// Stored data that no longer forms a valid domain model.
/// `guardingStorage` turns this into `DomainError.storage`.
nonisolated struct CorruptRecordError: Error, CustomStringConvertible {
    let description: String
}

extension PatientRecord {
    nonisolated func toDomain() throws -> Patient {
        Patient(id: Patient.ID(id),
                name: try PersonName(name),
                birthDate: try birthDate.map { try BirthDate($0, asOf: Date()) },
                registeredAt: registeredAt)
    }
}

extension ConditionRecord {
    nonisolated func toDomain() throws -> Condition {
        guard let patient else {
            throw CorruptRecordError(description: "Condition \(id) has no patient")
        }
        return Condition(id: Condition.ID(id),
                         patientID: Patient.ID(patient.id),
                         name: try ConditionName(name),
                         onsetDate: onsetDate,
                         status: resolvedAt.map { .resolved(on: $0) } ?? .active,
                         createdAt: createdAt)
    }
}

extension SeverityEntryRecord {
    nonisolated func toDomain() throws -> SeverityEntry {
        guard let condition else {
            throw CorruptRecordError(description: "Severity entry \(id) has no condition")
        }
        return SeverityEntry(id: SeverityEntry.ID(id),
                             conditionID: Condition.ID(condition.id),
                             score: try SeverityScore(score),
                             recordedAt: recordedAt,
                             note: try note.map { try ClinicalNote($0) })
    }
}
