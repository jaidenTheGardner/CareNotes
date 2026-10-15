//
//  SeverityBadge.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Shows a seveirty score and its band as a compact coloured pill.

// Business Rule: Severity is never shown by colour alone. It also
// has a symbol and text label.

import SwiftUI

struct SeverityBadge: View {
    let score: SeverityScore

    var body: some View {
        let band = score.band
        Label {
            Text("\(score.value)/10 · \(band.label)")
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: band.symbol)
        }
        .foregroundStyle(band.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(band.tint.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Severity \(score.value) out of 10, \(band.label)")
    }
}
