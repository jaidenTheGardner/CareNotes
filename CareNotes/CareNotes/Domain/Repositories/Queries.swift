//
//  Queries.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Independantly of a database, describes which conditions or
// severity entries to fetch.

// Business Rule: Every storage backend must filter and sort identically.

import Foundation

nonisolated enum ConditionStatusFilter: Sendable, Equatable {
    case any, active, resolved
}

nonisolated struct ConditionQuery: Sendable, Equatable {
    var patientID: Patient.ID?
    var status: ConditionStatusFilter
    var nameContains: String?

    init(patientID: Patient.ID? = nil, status: ConditionStatusFilter = .any, nameContains: String? = nil) {
        self.patientID = patientID
        self.status = status
        self.nameContains = nameContains
    }

    func matches(_ condition: Condition) -> Bool {
        if let patientID, condition.patientID != patientID { return false }
        switch status {
        case .any:      break
        case .active:   if !condition.isActive { return false }
        case .resolved: if condition.isActive { return false }
        }
        if let nameContains, !nameContains.isEmpty {
            let needle = TextRules.foldedKey(nameContains)
            if !condition.name.matchKey.contains(needle) { return false }
        }
        return true
    }
}

nonisolated enum ChronologicalOrder: Sendable, Equatable {
    case newestFirst, oldestFirst
}

nonisolated struct SeverityEntryQuery: Sendable, Equatable {
    var conditionID: Condition.ID?
    var recordedWithin: ClosedRange<Date>?
    var minimumBand: SeverityBand?
    var order: ChronologicalOrder
    var limit: Int?

    init(conditionID: Condition.ID? = nil,
         recordedWithin: ClosedRange<Date>? = nil,
         minimumBand: SeverityBand? = nil,
         order: ChronologicalOrder = .newestFirst,
         limit: Int? = nil) {
        self.conditionID = conditionID
        self.recordedWithin = recordedWithin
        self.minimumBand = minimumBand
        self.order = order
        self.limit = limit
    }

    func matches(_ entry: SeverityEntry) -> Bool {
        if let conditionID, entry.conditionID != conditionID { return false }
        if let recordedWithin, !recordedWithin.contains(entry.recordedAt) { return false }
        if let minimumBand, entry.score.band < minimumBand { return false }
        return true
    }

    /// Filter, sort and limit — reference behaviour for any repository.
    func apply(to entries: [SeverityEntry]) -> [SeverityEntry] {
        var result = entries.filter(matches)
        switch order {
        case .newestFirst: result.sort { $0.recordedAt > $1.recordedAt }
        case .oldestFirst: result.sort { $0.recordedAt < $1.recordedAt }
        }
        if let limit, limit >= 0 { result = Array(result.prefix(limit)) }
        return result
    }
}
