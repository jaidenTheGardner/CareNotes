//
//  LogSeveritySheet.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import SwiftUI

struct LogSeveritySheet: View {
    let environment: AppEnvironment
    let condition: Condition
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var score = 0.0
    @State private var note = ""
    @State private var recordedAt = Date.now
    @State private var errorMessage: String?
    @State private var isSaving = false

    private var currentBand: SeverityBand {
        (try? SeverityScore(Int(score)))?.band ?? .asymptomatic
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Text("\(Int(score))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(currentBand.tint)
                            .contentTransition(.numericText())
                        Label(currentBand.label, systemImage: currentBand.symbol)
                            .font(.headline)
                            .foregroundStyle(currentBand.tint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .accessibilityHidden(true)

                    Slider(value: $score, in: 0...10, step: 1) {
                        Text("Severity")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("10")
                    }
                    .accessibilityLabel("Severity")
                    .accessibilityValue("\(Int(score)) out of 10, \(currentBand.label)")
                } header: {
                    Text("How severe is it?")
                } footer: {
                    Text("0 means no symptoms, 10 is the worst imaginable.")
                }

                Section("When") {
                    DatePicker("Recorded", selection: $recordedAt,
                               in: condition.onsetDate...Date.now,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section("Note (optional)") {
                    FormTextField(title: "Triggers, medication taken, how it feels…",
                              text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Log Severity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                _ = try await environment.logSeverityEntry.execute(
                    .init(conditionID: condition.id, score: Int(score), note: note, recordedAt: recordedAt)
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
