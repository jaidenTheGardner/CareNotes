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

@main
struct CareNotesApp: App {
    private let environment = AppEnvironment.inMemory()

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
        }
    }
}
