//
//  CareNotesApp.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

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
