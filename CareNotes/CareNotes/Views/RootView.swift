//
//  RootView.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        PatientListView(environment: environment)
    }
}
