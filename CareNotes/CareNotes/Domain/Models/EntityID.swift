//
//  EntityID.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

import Foundation

nonisolated struct EntityID<Entity>: Hashable, Sendable, CustomStringConvertible {
    let rawValue: UUID
    init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    var description: String { rawValue.uuidString }
}
