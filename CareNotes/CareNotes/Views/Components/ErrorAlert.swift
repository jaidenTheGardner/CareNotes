//
//  ErrorAlert.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Provides an alert that appears whenerver an operation reports
// an error message.

// Business Rule: Users are always told when an action fails,
// using the plain-language domain error message.

import SwiftUI

extension View {
    // Presents an alert whenever `message` is non-nil and clears it on dismiss.
    func errorAlert(_ message: Binding<String?>) -> some View {
        alert(
            "Something went wrong",
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
