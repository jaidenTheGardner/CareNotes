//
//  DateProviding.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated protocol DateProviding: Sendable {
    func now() -> Date
}

nonisolated struct SystemDateProvider: DateProviding {
    init() {}
    func now() -> Date { Date() }
}
