//
//  ConditionDetailViewModel.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Loads a condition's entries and trend for its detail screen and
// carries out resolving it.

// Business Rule: Trend and resolution decisions come from the use
// cases so the screen never applies business rules itself. A trend
// needs at least 2 entries in the chosen window.

import Foundation
import Observation

@Observable
final class ConditionDetailViewModel {
    private let environment: AppEnvironment

    var condition: Condition
    var entries: [SeverityEntry] = []          // newest first
    var trend: ConditionTrend?
    var trendMessage: String?
    var windowDays = 14 {
        didSet { if oldValue != windowDays { Task { await refreshTrend() } } }
    }
    var errorMessage: String?

    init(environment: AppEnvironment, condition: Condition) {
        self.environment = environment
        self.condition = condition
    }

    var chronologicalEntries: [SeverityEntry] { entries.reversed() }

    func load() async {
        do {
            entries = try await environment.loadEntries.execute(conditionID: condition.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshTrend()
    }

    func refreshTrend() async {
        do {
            trend = try await environment.assessTrend.execute(
                .init(conditionID: condition.id, windowDays: windowDays)
            )
            trendMessage = nil
        } catch DomainError.insufficientData(let required, _) {
            trend = nil
            trendMessage = "Log at least \(required) entries within the last \(windowDays) days to see a trend."
        } catch {
            trend = nil
            errorMessage = error.localizedDescription
        }
    }

    func resolve() async {
        do {
            condition = try await environment.resolveCondition.execute(.init(conditionID: condition.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
