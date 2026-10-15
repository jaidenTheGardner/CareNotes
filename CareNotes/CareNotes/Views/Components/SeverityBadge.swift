//
//  SeverityBadge.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

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
