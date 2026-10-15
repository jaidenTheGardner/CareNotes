//
//  NewConditionSheet.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import SwiftUI

struct NewConditionSheet: View {
    let environment: AppEnvironment
    let patientID: Patient.ID
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var onsetDate = Date.now
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Condition") {
                    FormTextField(title: "e.g. Migraine, Lower back pain", text: $name)
                        .autocorrectionDisabled()
                }
                Section {
                    DatePicker("Started", selection: $onsetDate,
                               in: ...Date.now, displayedComponents: .date)
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Condition")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                _ = try await environment.recordCondition.execute(
                    .init(patientID: patientID, name: name, onsetDate: onsetDate)
                )
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
