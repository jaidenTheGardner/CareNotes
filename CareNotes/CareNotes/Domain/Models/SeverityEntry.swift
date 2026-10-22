//
//  SeverityEntry.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Represents one dated severity observation for a condition,
// with an optimal note.

// Business Rule: Every entry belongs to exactly one condition
// and always carries a valid 0-10 severity score.

import Foundation

nonisolated struct SeverityEntry: Identifiable, Hashable, Sendable {
    typealias ID = EntityID<SeverityEntry>

    let id: ID
    let conditionID: Condition.ID
    let score: SeverityScore
    let recordedAt: Date
    var note: ClinicalNote?

    init(id: ID = ID(),
         conditionID: Condition.ID,
         score: SeverityScore,
         recordedAt: Date,
         note: ClinicalNote? = nil) {
        self.id = id
        self.conditionID = conditionID
        self.score = score
        self.recordedAt = recordedAt
        self.note = note
    }
}
