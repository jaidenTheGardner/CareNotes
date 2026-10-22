//
//  DateProviding.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Supplies the current date and time to the application.

// Business Rule: Rules that depend on current time use this
// one clock to preserve consistencey.

import Foundation

nonisolated protocol DateProviding: Sendable {
    func now() -> Date
}

nonisolated struct SystemDateProvider: DateProviding {
    init() {}
    func now() -> Date { Date() }
}
