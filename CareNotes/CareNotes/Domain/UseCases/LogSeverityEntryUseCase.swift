//
//  LogSeverityEntryUse.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated struct LogSeverityEntryUseCase: Sendable {
    struct Request: Sendable {
        var conditionID: Condition.ID
        var score: Int
        var note: String?
        /// Defaults to "now" when nil.
        var recordedAt: Date?

        init(conditionID: Condition.ID, score: Int, note: String? = nil, recordedAt: Date? = nil) {
            self.conditionID = conditionID
            self.score = score
            self.note = note
            self.recordedAt = recordedAt
        }
    }

    private let conditions: any ConditionRepository
    private let entries: any SeverityEntryRepository
    private let dates: any DateProviding
    private let calendar: Calendar

    init(conditions: any ConditionRepository,
         entries: any SeverityEntryRepository,
         dates: any DateProviding = SystemDateProvider(),
         calendar: Calendar = .current) {
        self.conditions = conditions
        self.entries = entries
        self.dates = dates
        self.calendar = calendar
    }

    func execute(_ request: Request) async throws -> SeverityEntry {
        let now = dates.now()
        let recordedAt = request.recordedAt ?? now

        let score = try validating { try SeverityScore(request.score) }
        let note: ClinicalNote? = try validating {
            guard let raw = request.note,
                  !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return try ClinicalNote(raw)
        }

        guard recordedAt <= now else { throw DomainError.entryDatedInFuture }

        let found = try await guardingStorage { try await conditions.condition(withID: request.conditionID) }
        guard let condition = found else { throw DomainError.conditionNotFound(request.conditionID) }
        guard condition.isActive else { throw DomainError.conditionAlreadyResolved(condition.id) }
        guard recordedAt >= calendar.startOfDay(for: condition.onsetDate) else {
            throw DomainError.entryPredatesOnset
        }

        let entry = SeverityEntry(conditionID: condition.id, score: score, recordedAt: recordedAt, note: note)
        try await guardingStorage { try await entries.save(entry) }
        return entry
    }
}
