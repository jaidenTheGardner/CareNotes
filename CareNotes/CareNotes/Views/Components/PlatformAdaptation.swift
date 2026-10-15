//
//  PlatformAdaptation.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Keeps forms and sheets looking the same on iPhone, iPad and Mac

// Business Rule: Every data-entry field shows a clear in-field prompt
// so users know what to enter on eveyr device.

import SwiftUI

// A text field thats text is always an in-field placeholder.
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
