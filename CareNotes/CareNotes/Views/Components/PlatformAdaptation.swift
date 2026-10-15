//
//  PlatformAdaptation.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import SwiftUI

// A text field whose text is always an in-field placeholder (never a side label).
struct FormTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(title, text: $text, prompt: Text(title), axis: axis)
            .labelsHidden()                       // hides the side label; VoiceOver still reads `title`
            .accessibilityLabel(title)
    }
}

extension View {
    // Gives form sheets a sensible size on Mac / iPad instead of a cramped default.
    func formSheetSizing() -> some View {
        presentationSizing(.form)
    }
}
