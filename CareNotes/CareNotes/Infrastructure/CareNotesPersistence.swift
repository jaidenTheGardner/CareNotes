//
//  CareNotesPersistence.swift
//  CareNotes
//

// Builds the SwiftData container that holds all CareNotes records.

// Business Rule: Patient health data stays on this device. CloudKit
// sync is switched off explicitly, so no data leaves the phone.

import Foundation
import SwiftData

nonisolated enum CareNotesPersistence {
    static let schema = Schema([PatientRecord.self, ConditionRecord.self, SeverityEntryRecord.self])

    /// - Parameters:
    ///   - inMemory: true for tests and previews; nothing is written to disk.
    ///   - storeURL: a custom file location (used by tests); defaults to the app's store.
    static func makeContainer(inMemory: Bool = false, storeURL: URL? = nil) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else if let storeURL {
            configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration("CareNotes", schema: schema, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
