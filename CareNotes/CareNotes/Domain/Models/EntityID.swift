//
//  EntityID.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Provides a typed identifier so each kind of record has its
// own ID type.

// Business Rule: Records of differet kinds can not be mixed up.

import Foundation

nonisolated struct EntityID<Entity>: Hashable, Sendable, CustomStringConvertible {
    let rawValue: UUID
    init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    var description: String { rawValue.uuidString }
}
