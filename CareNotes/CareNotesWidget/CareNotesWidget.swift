import SwiftUI
import WidgetKit

private enum WidgetStorage {
    // Keep in sync with CareNotesWidgetPublisher in the containing app.
    static let groupID = "group.iOSGroup.CareNotes"
    static let countKey = "careNotes.patientCount"

    static func readCount() -> Int? {
        guard let defaults = UserDefaults(suiteName: groupID),
              defaults.object(forKey: countKey) != nil else {
            return nil
        }
        return max(0, defaults.integer(forKey: countKey))
    }
}

struct CareNotesEntry: TimelineEntry {
    let date: Date
    let patientCount: Int?
}

struct CareNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> CareNotesEntry {
        CareNotesEntry(date: .now, patientCount: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (CareNotesEntry) -> Void) {
        completion(CareNotesEntry(
            date: .now,
            patientCount: context.isPreview ? 3 : WidgetStorage.readCount()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareNotesEntry>) -> Void) {
        let entry = CareNotesEntry(date: .now, patientCount: WidgetStorage.readCount())
        // Request a fallback refresh; app writes also request a timeline reload.
        let update = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(update)))
    }
}

struct CareNotesSummaryView: View {
    let entry: CareNotesEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("CareNotes", systemImage: "cross.case.fill")
                .font(.headline)
                .foregroundStyle(.teal)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            if let patientCount = entry.patientCount {
                Text(patientCount.formatted())
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(patientCount) patient records")

                Text(patientCount == 1 ? "Patient record" : "Patient records")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Open CareNotes")
                    .font(.subheadline.weight(.semibold))

                Text("Your records stay private")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if family == .systemMedium {
                Text("At a glance, without personal health details")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color.teal.opacity(0.12)
        }
    }
}

struct CareNotesWidget: Widget {
    let kind = "CareNotesSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CareNotesProvider()) { entry in
            CareNotesSummaryView(entry: entry)
        }
        .configurationDisplayName("CareNotes Overview")
        .description("A privacy-conscious count of saved patient records.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
