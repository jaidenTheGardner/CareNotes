//
//  ResolveConditionUseCase.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated struct ResolveConditionUseCase: Sendable {
    struct Request: Sendable {
        var conditionID: Condition.ID
        /// Defaults to "now" when nil.
        var resolvedOn: Date?
        init(conditionID: Condition.ID, resolvedOn: Date? = nil) {
            self.conditionID = conditionID
            self.resolvedOn = resolvedOn
        }
    }

    private let conditions: any ConditionRepository
    private let dates: any DateProviding

    init(conditions: any ConditionRepository, dates: any DateProviding = SystemDateProvider()) {
        self.conditions = conditions
        self.dates = dates
    }

    func execute(_ request: Request) async throws -> Condition {
        let now = dates.now()
        let resolvedOn = request.resolvedOn ?? now
        guard resolvedOn <= now else { throw DomainError.validation(.dateInFuture(.resolvedOn)) }

        let found = try await guardingStorage { try await conditions.condition(withID: request.conditionID) }
        guard var condition = found else { throw DomainError.conditionNotFound(request.conditionID) }

        try condition.resolve(on: resolvedOn)   // entity enforces lifecycle rules
        let resolved = condition
        try await guardingStorage { try await conditions.save(resolved) }
        return resolved
    }
}
