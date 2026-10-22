//
//  SeverityPresentation.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Maps severity bands and trend directions to display labels,
// colours and symbols.

// business Rule: Bands follow the score ranges and each has
// its own symbol.

import SwiftUI

extension SeverityBand {
    var label: String {
        switch self {
        case .asymptomatic: "None"
        case .mild:         "Mild"
        case .moderate:     "Moderate"
        case .severe:       "Severe"
        }
    }

    var tint: Color {
        switch self {
        case .asymptomatic: .green
        case .mild:         .teal
        case .moderate:     .orange
        case .severe:       .red
        }
    }

    var symbol: String {
        switch self {
        case .asymptomatic: "checkmark.circle.fill"
        case .mild:         "minus.circle.fill"
        case .moderate:     "exclamationmark.triangle.fill"
        case .severe:       "exclamationmark.octagon.fill"
        }
    }
}

extension TrendDirection {
    var label: String {
        switch self {
        case .improving: "Improving"
        case .stable:    "Stable"
        case .worsening: "Worsening"
        }
    }

    var symbol: String {
        switch self {
        case .improving: "arrow.down.right.circle.fill"
        case .stable:    "arrow.right.circle.fill"
        case .worsening: "arrow.up.right.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .improving: .green
        case .stable:    .secondary
        case .worsening: .red
        }
    }
}
