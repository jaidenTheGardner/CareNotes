//
//  Patient.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

// Represents a person whose conditions are tracked in the app.

// Business Rule: A patient must have a valid name. The date of
// birth is optional, but must be valid if given.

import Foundation

nonisolated struct Patient: Identifiable, Hashable, Sendable {
    typealias ID = EntityID<Patient>

    let id: ID
    var name: PersonName
    var birthDate: BirthDate?
    let registeredAt: Date

    init(id: ID = ID(), name: PersonName, birthDate: BirthDate? = nil, registeredAt: Date) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.registeredAt = registeredAt
    }
}
