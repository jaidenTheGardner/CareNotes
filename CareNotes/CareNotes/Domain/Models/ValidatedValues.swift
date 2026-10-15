//
//  ValidatedValues.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Defines validated types for names, notes, severity scores and
// birth dates that can be created with valid data.

// Business Rule: Severity is 0-10, names are limited to 100
// characters, notes to 2,000 and a birth date cannot be in the
// future or over 130 years ago.


import Foundation

nonisolated enum TextRules {
    static func normalised(_ raw: String,
                           field: ValidationField,
                           maxLength: Int,
                           collapseWhitespace: Bool) throws -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if collapseWhitespace {
            text = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }
        guard !text.isEmpty else { throw ValidationError.empty(field) }
        guard text.count <= maxLength else { throw ValidationError.tooLong(field, maxLength: maxLength) }
        return text
    }

    static func foldedKey(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

// MARK: - Text values

nonisolated struct PersonName: Hashable, Sendable, CustomStringConvertible {
    static let maxLength = 100
    let value: String
    init(_ raw: String) throws {
        value = try TextRules.normalised(raw, field: .patientName, maxLength: Self.maxLength, collapseWhitespace: true)
    }
    var description: String { value }
}

nonisolated struct ConditionName: Hashable, Sendable, CustomStringConvertible {
    static let maxLength = 120
    let value: String
    init(_ raw: String) throws {
        value = try TextRules.normalised(raw, field: .conditionName, maxLength: Self.maxLength, collapseWhitespace: true)
    }
    /// Case- and diacritic-insensitive key used to detect duplicates.
    var matchKey: String { TextRules.foldedKey(value) }
    var description: String { value }
}

nonisolated struct ClinicalNote: Hashable, Sendable, CustomStringConvertible {
    static let maxLength = 2_000
    let value: String
    init(_ raw: String) throws {
        // Newlines are meaningful in free-text notes, so whitespace isn't collapsed.
        value = try TextRules.normalised(raw, field: .clinicalNote, maxLength: Self.maxLength, collapseWhitespace: false)
    }
    var description: String { value }
}

// MARK: - Severity

/// Patient-reported severity on the common 0–10 numeric rating scale.
nonisolated struct SeverityScore: Hashable, Sendable, Comparable, CustomStringConvertible {
    static let range = 0...10
    let value: Int
    init(_ value: Int) throws {
        guard Self.range.contains(value) else {
            throw ValidationError.outOfRange(.severityScore, allowed: Self.range)
        }
        self.value = value
    }
    var band: SeverityBand { SeverityBand(score: self) }
    static func < (lhs: SeverityScore, rhs: SeverityScore) -> Bool { lhs.value < rhs.value }
    var description: String { "\(value)/10" }
}

nonisolated enum SeverityBand: Int, CaseIterable, Comparable, Sendable {
    case asymptomatic   // 0
    case mild           // 1–3
    case moderate       // 4–6
    case severe         // 7–10

    init(score: SeverityScore) {
        switch score.value {
        case 0:      self = .asymptomatic
        case 1...3:  self = .mild
        case 4...6:  self = .moderate
        default:     self = .severe
        }
    }

    static func < (lhs: SeverityBand, rhs: SeverityBand) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - Dates

nonisolated struct BirthDate: Hashable, Sendable {
    let value: Date
    init(_ date: Date, asOf now: Date, calendar: Calendar = .current) throws {
        guard date <= now else { throw ValidationError.dateInFuture(.dateOfBirth) }
        guard let earliest = calendar.date(byAdding: .year, value: -130, to: now), date >= earliest else {
            throw ValidationError.dateImplausible(.dateOfBirth)
        }
        value = calendar.startOfDay(for: date)
    }
    func age(asOf now: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.year], from: value, to: now).year ?? 0
    }
}
