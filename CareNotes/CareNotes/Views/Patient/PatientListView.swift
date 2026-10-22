//
//  PatientListView.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Home Screen listing every registered patient.

// Business Rule: A patient must be registered before any
// condition can be tracked for them.

import SwiftUI

struct PatientListView: View {
    let environment: AppEnvironment
    @State private var model: PatientListViewModel
    @State private var isPresentingNew = false

    init(environment: AppEnvironment) {
        self.environment = environment
        _model = State(initialValue: PatientListViewModel(environment: environment))
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.patients.isEmpty && !model.isLoading {
                    ContentUnavailableView {
                        Label("No Patients Yet", systemImage: "person.crop.circle.badge.plus")
                    } description: {
                        Text("Add a patient to start recording conditions and how severe they are.")
                    } actions: {
                        Button("Add Patient") { isPresentingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(model.patients) { patient in
                        NavigationLink(value: patient) {
                            PatientRow(patient: patient)
                        }
                    }
                }
            }
            .navigationTitle("Patients")
            .navigationDestination(for: Patient.self) { patient in
                PatientDetailView(environment: environment, patient: patient)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isPresentingNew = true } label: {
                        Label("Add Patient", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNew) {
                NewPatientSheet(environment: environment) {
                    Task { await model.load() }
                }
            }
            .task { await model.load() }
            .errorAlert($model.errorMessage)
        }
    }
}

struct PatientRow: View {
    let patient: Patient

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(patient.name.value)
                .font(.headline)
            if let birthDate = patient.birthDate {
                Text("Age \(birthDate.age(asOf: .now))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
