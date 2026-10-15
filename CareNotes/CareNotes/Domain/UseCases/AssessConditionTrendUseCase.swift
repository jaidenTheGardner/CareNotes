//
//  AssessConditionTrendUseCase.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Works out whether a condition is improving, stable or worsening
// by comparing the first and second half of a time window.

// Business Rule: At least 2 entries are needed with a 2-365 day
// window, as well as an average change of 1 point or more counts
// as improving or worsening.

import Foundation

nonisolated struct AssessConditionTrendUseCase: Sendable {
    struct Request: Sendable {
        var conditionID: Condition.ID
        var windowDays: Int
        init(conditionID: Condition.ID, windowDays: Int = 14) {
            self.conditionID = conditionID
            self.windowDays = windowDays
        }
    }

    static let minimumEntries = 2
    static let windowDaysRange = 2...365
    static let threshold = 1.0

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

    func execute(_ request: Request) async throws -> ConditionTrend {
        guard Self.windowDaysRange.contains(request.windowDays) else {
            throw DomainError.validation(.outOfRange(.trendWindow, allowed: Self.windowDaysRange))
        }

        let found = try await guardingStorage { try await conditions.condition(withID: request.conditionID) }
        guard let condition = found else { throw DomainError.conditionNotFound(request.conditionID) }

        let now = dates.now()
        guard let start = calendar.date(byAdding: .day, value: -request.windowDays, to: now) else {
            throw DomainError.validation(.outOfRange(.trendWindow, allowed: Self.windowDaysRange))
        }
        let window = start...now

        let inWindow = try await guardingStorage {
            try await entries.entries(matching: SeverityEntryQuery(conditionID: condition.id,
                                                                   recordedWithin: window,
                                                                   order: .oldestFirst))
        }
        guard inWindow.count >= Self.minimumEntries, let latest = inWindow.last else {
            throw DomainError.insufficientData(required: Self.minimumEntries, available: inWindow.count)
        }

        let half = inWindow.count / 2
        let earlier = Self.average(of: inWindow.prefix(half))
        let later = Self.average(of: inWindow.suffix(half))
        let delta = later - earlier
        let direction: TrendDirection =
            delta >= Self.threshold ? .worsening :
            delta <= -Self.threshold ? .improving : .stable

        return ConditionTrend(conditionID: condition.id,
                              direction: direction,
                              earlierAverage: earlier,
                              laterAverage: later,
                              latest: latest,
                              peak: inWindow.map(\.score).max() ?? latest.score,
                              entryCount: inWindow.count,
                              window: window)
    }

    private static func average(of entries: ArraySlice<SeverityEntry>) -> Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.reduce(0) { $0 + $1.score.value }) / Double(entries.count)
    }
}
