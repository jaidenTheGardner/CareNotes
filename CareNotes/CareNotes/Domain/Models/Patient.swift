//
//  Patient.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

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
