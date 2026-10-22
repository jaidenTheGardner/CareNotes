//
//  PatientDetailView.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Lists one patient's conditions, split intoo active and resolved,
// wth the latest severity for each.

// Business Rule: Active conditions are shown before resolved ones,
// and resolved conditions stay visible so history is never lost.

import SwiftUI

struct PatientDetailView: View {
    let environment: AppEnvironment
    @State private var model: PatientDetailViewModel
    @State private var isPresentingNew = false
    @State private var isEditingPatient = false
    /// Tells the patient list to refresh after an edit.
    private let onPatientChanged: () -> Void

    init(environment: AppEnvironment, patient: Patient, onPatientChanged: @escaping () -> Void = {}) {
        self.environment = environment
        self.onPatientChanged = onPatientChanged
        _model = State(initialValue: PatientDetailViewModel(environment: environment, patient: patient))
    }

    var body: some View {
        List {            
            if model.conditions.isEmpty {
                ContentUnavailableView {
                    Label("No Conditions", systemImage: "cross.case")
                } description: {
                    Text("Add a condition to begin logging its severity.")
                } actions: {
                    Button("Add Condition") { isPresentingNew = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            if !model.activeConditions.isEmpty {
                Section("Active") {
                    ForEach(model.activeConditions) { condition in
                        row(for: condition)
                    }
                }
            }
            if !model.resolvedConditions.isEmpty {
                Section("Resolved") {
                    ForEach(model.resolvedConditions) { condition in
                        row(for: condition)
                    }
                }
            }
        }
        .navigationTitle(model.patient.name.value)
        .navigationDestination(for: Condition.self) { condition in
            ConditionDetailView(environment: environment, condition: condition)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isPresentingNew = true } label: {
                    Label("Add Condition", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { isEditingPatient = true } label: {
                    Label("Edit Patient", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $isEditingPatient) {
            NewPatientSheet(environment: environment, patient: model.patient) {
                Task {
                    await model.reloadPatient()
                    onPatientChanged()
                }
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            NewConditionSheet(environment: environment, patientID: model.patient.id) {
                Task { await model.load() }
            }
        }
        .onAppear { Task { await model.load() } }
        .errorAlert($model.errorMessage)
    }

    private func row(for condition: Condition) -> some View {
        NavigationLink(value: condition) {
            ConditionRow(condition: condition, latest: model.latestEntries[condition.id])
        }
    }
}

struct ConditionRow: View {
    let condition: Condition
    let latest: SeverityEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(condition.name.value)
                .font(.headline)
            HStack(spacing: 8) {
                if let resolved = condition.resolvedDate {
                    Label("Resolved \(resolved.formatted(date: .abbreviated, time: .omitted))",
                          systemImage: "checkmark.seal")
                        .foregroundStyle(.secondary)
                } else if let latest {
                    SeverityBadge(score: latest.score)
                } else {
                    Text("No entries yet")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
