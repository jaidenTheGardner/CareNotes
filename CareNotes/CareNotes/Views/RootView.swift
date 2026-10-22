//
//  RootView.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Top-level screen that applies the app's accent colour and hosts
// the patient list.

// Business Rule: All screens are built from the same environment, so
// the same business rules apply everywhere.

import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        PatientListView(environment: environment)
    }
}
