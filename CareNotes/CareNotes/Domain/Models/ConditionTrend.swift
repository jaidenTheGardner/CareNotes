//
//  ConditionTrend.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Summarises how a condition's recorded severity changed
// over a time window.

// Business Rule: A trend only describes the scores that were
// logged. It is not presented as a diagnosis or medical advice.

import Foundation

nonisolated enum TrendDirection: Sendable, Equatable {
    case improving, stable, worsening
}

nonisolated struct ConditionTrend: Sendable, Equatable {
    let conditionID: Condition.ID
    let direction: TrendDirection
    let earlierAverage: Double
    let laterAverage: Double
    let latest: SeverityEntry
    let peak: SeverityScore
    let entryCount: Int
    let window: ClosedRange<Date>

    var change: Double { laterAverage - earlierAverage }
}
