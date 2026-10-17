//
//  CareNotesApp.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// App entry point that creates the environment and shows the root
// screen on iPhone, iPad and Mac.

// Business Rule: the app ships with no preloaded patient data. Every
// record exists because it was entered by a user.

import SwiftUI
import os

@main
struct CareNotesApp: App {
    /// nil only if the on-device store couldn't be opened.
    private let environment: AppEnvironment?

    init() {
        do {
            environment = .swiftData(container: try CareNotesPersistence.makeContainer())
        } catch {
            Logger(subsystem: "CareNotes", category: "Persistence")
                .error("Failed to open store: \(error.localizedDescription, privacy: .public)")
            environment = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let environment {
                RootView(environment: environment)
            } else {
                StoreUnavailableView()
            }
        }
    }
}

/// Shown instead of crashing when the store can't open (e.g. a full disk).
private struct StoreUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Couldn't Open Your Notes", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("CareNotes couldn't open its on-device storage. Close the app and try again. If this keeps happening, check you have free storage space or contact support.")
        }
    }
}
