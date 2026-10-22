//
//  TrendCard.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Displays whether a condition is improving, stable of worsening, with
// the supporting averages.

// Business Rule: The trend is always labelled as a summary of logged
// data and not medical advice.

import SwiftUI

struct TrendCard: View {
    let trend: ConditionTrend
    let windowDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(trend.direction.label)
                    .font(.headline)
            } icon: {
                Image(systemName: trend.direction.symbol)
                    .foregroundStyle(trend.direction.tint)
            }

            Text("Average score moved from \(trend.earlierAverage, format: .number.precision(.fractionLength(1))) to \(trend.laterAverage, format: .number.precision(.fractionLength(1))) across \(trend.entryCount) entries in the last \(windowDays) days. Highest recorded: \(trend.peak.value)/10.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("A summary of what was logged, not medical advice.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}
