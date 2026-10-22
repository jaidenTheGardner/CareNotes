// The only health-data summary exposed to the Home Screen widget.
// Individual names, conditions and severity history stay in SwiftData.
import Foundation
import WidgetKit

enum CareNotesWidgetPublisher {
    // Must match both targets' App Group entitlements and the widget provider.
    static let groupID = "group.iOSGroup.CareNotes"
    static let countKey = "careNotes.patientCount"
    static let kind = "CareNotesSummaryWidget"

    /// Publish a new count only after the patient list was loaded successfully.
    static func publish(patientCount: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: groupID) else {
            // Inability to share never blocks a user's primary care workflow.
            return
        }

        sharedDefaults.set(max(0, patientCount), forKey: countKey)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
