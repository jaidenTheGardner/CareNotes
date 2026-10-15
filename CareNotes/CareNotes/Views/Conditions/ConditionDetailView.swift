//
//  ConditionDetailView.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import SwiftUI
import Charts

struct ConditionDetailView: View {
    let environment: AppEnvironment
    @State private var model: ConditionDetailViewModel
    @State private var isLogging = false
    @State private var isConfirmingResolve = false

    init(environment: AppEnvironment, condition: Condition) {
        self.environment = environment
        _model = State(initialValue: ConditionDetailViewModel(environment: environment, condition: condition))
    }

    var body: some View {
        List {
            statusSection
            trendSection
            if model.entries.count >= 2 { chartSection }
            entriesSection
        }
        .navigationTitle(model.condition.name.value)
        .toolbar {
            if model.condition.isActive {
                ToolbarItem(placement: .primaryAction) {
                    Button { isLogging = true } label: {
                        Label("Log Severity", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Mark as Resolved", systemImage: "checkmark.seal") {
                        isConfirmingResolve = true
                    }
                }
            }
        }
        .confirmationDialog("Mark this condition as resolved?",
                            isPresented: $isConfirmingResolve,
                            titleVisibility: .visible) {
            Button("Mark as Resolved") { Task { await model.resolve() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't be able to log new entries, but the history is kept.")
        }
        .sheet(isPresented: $isLogging) {
            LogSeveritySheet(environment: environment, condition: model.condition) {
                Task { await model.load() }
            }
        }
        .task { await model.load() }
        .errorAlert($model.errorMessage)
    }

    // MARK: Sections

    private var statusSection: some View {
        Section {
            LabeledContent("Started") {
                Text(model.condition.onsetDate, format: .dateTime.day().month().year())
            }
            if let resolved = model.condition.resolvedDate {
                LabeledContent("Resolved") {
                    Text(resolved, format: .dateTime.day().month().year())
                }
            } else if let latest = model.entries.first {
                LabeledContent("Latest") { SeverityBadge(score: latest.score) }
            }
        }
    }

    private var trendSection: some View {
        Section {
            Picker("Window", selection: $model.windowDays) {
                Text("7 days").tag(7)
                Text("14 days").tag(14)
                Text("30 days").tag(30)
            }
            .pickerStyle(.segmented)

            if let trend = model.trend {
                TrendCard(trend: trend, windowDays: model.windowDays)
            } else if let message = model.trendMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Trend")
        }
    }

    private var chartSection: some View {
        Section("Severity over time") {
            Chart(model.chronologicalEntries) { entry in
                LineMark(x: .value("Date", entry.recordedAt),
                         y: .value("Severity", entry.score.value))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Date", entry.recordedAt),
                          y: .value("Severity", entry.score.value))
                    .foregroundStyle(entry.score.band.tint)
            }
            .chartYScale(domain: 0...10)
            .chartYAxis { AxisMarks(values: [0, 2, 4, 6, 8, 10]) }
            .frame(height: 180)
            .accessibilityLabel("Severity over time")
            .accessibilityValue(chartSummary)
        }
    }

    private var chartSummary: String {
        let values = model.chronologicalEntries.map { String($0.score.value) }.joined(separator: ", ")
        return "Scores from oldest to newest: \(values)"
    }

    private var entriesSection: some View {
        Section("Entries") {
            if model.entries.isEmpty {
                ContentUnavailableView {
                    Label("No Entries", systemImage: "waveform.path.ecg")
                } description: {
                    Text(model.condition.isActive
                         ? "Tap + to log how severe this is right now."
                         : "No entries were logged for this condition.")
                }
                .listRowBackground(Color.clear)
            }
            ForEach(model.entries) { entry in
                EntryRow(entry: entry)
            }
        }
    }
}

struct EntryRow: View {
    let entry: SeverityEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SeverityBadge(score: entry.score)
                Spacer()
                Text(entry.recordedAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let note = entry.note {
                Text(note.value)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
