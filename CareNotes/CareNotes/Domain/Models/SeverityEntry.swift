//
//  SeverityEntry.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//


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
