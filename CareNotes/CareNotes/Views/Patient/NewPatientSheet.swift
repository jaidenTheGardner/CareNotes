//
//  NewPatientSheet.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Form for registerig a new patient with a name and optional date
// of birth.

// Business Rule: A name is required and a date of birth cannot be in
// the future. The Save button stays disabled until a name is entered.

import SwiftUI

struct NewPatientSheet: View {
    let environment: AppEnvironment
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var includesBirthDate = false
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    FormTextField(title: "Full name", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }
                Section {
                    Toggle("Record date of birth", isOn: $includesBirthDate)
                    if includesBirthDate {
                        DatePicker("Date of birth", selection: $birthDate,
                                   in: ...Date.now, displayedComponents: .date)
                    }
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Patient")
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
                _ = try await environment.registerPatient.execute(
                    .init(name: name, dateOfBirth: includesBirthDate ? birthDate : nil)
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
