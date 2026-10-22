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
    let patient: Patient?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var includesBirthDate = false
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    init(environment: AppEnvironment, patient: Patient? = nil, onSaved: @escaping () -> Void) {
        self.environment = environment
        self.patient = patient
        self.onSaved = onSaved
        _name = State(initialValue: patient?.name.value ?? "")
        _includesBirthDate = State(initialValue: patient?.birthDate != nil)
        if let existing = patient?.birthDate?.value {
            _birthDate = State(initialValue: existing)
        }
    }

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
            .navigationTitle(patient == nil ? "New Patient" : "Edit Patient")            .toolbar {
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
                let dateOfBirth = includesBirthDate ? birthDate : nil
                if let patient {
                    _ = try await environment.updatePatient.execute(
                        .init(patientID: patient.id, name: name, dateOfBirth: dateOfBirth)
                    )
                } else {
                    _ = try await environment.registerPatient.execute(
                        .init(name: name, dateOfBirth: dateOfBirth)
                    )
                }
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
