//
//  AppEnvironment.swift
//  CareNotes
//
//  Created by Jaiden Gardner on 15/10/2026.
//

//Composition root that builds every use case from the chosen
//repositories and closk

// Business Rule: Screens reach patient data only through use cases,
// not directly through storage, so evey rule is enforced in one place.

import Foundation
import SwiftData

struct AppEnvironment {
    let registerPatient: RegisterPatientUseCase
    let updatePatient: UpdatePatientUseCase
    let deletePatient: DeletePatientUseCase
    let recordCondition: RecordConditionUseCase
    let logSeverityEntry: LogSeverityEntryUseCase
    let resolveCondition: ResolveConditionUseCase
    let assessTrend: AssessConditionTrendUseCase
    let loadPatients: LoadPatientsUseCase
    let loadConditions: LoadConditionsUseCase
    let loadEntries: LoadEntriesUseCase

    static func make(patients: any PatientRepository,
                     conditions: any ConditionRepository,
                     entries: any SeverityEntryRepository,
                     dates: any DateProviding = SystemDateProvider()) -> AppEnvironment {
        AppEnvironment(
            registerPatient: RegisterPatientUseCase(patients: patients, dates: dates),
            updatePatient: UpdatePatientUseCase(patients: patients, dates: dates),
            deletePatient: DeletePatientUseCase(patients: patients),
            recordCondition: RecordConditionUseCase(patients: patients, conditions: conditions, dates: dates),
            logSeverityEntry: LogSeverityEntryUseCase(conditions: conditions, entries: entries, dates: dates),
            resolveCondition: ResolveConditionUseCase(conditions: conditions, dates: dates),
            assessTrend: AssessConditionTrendUseCase(conditions: conditions, entries: entries, dates: dates),
            loadPatients: LoadPatientsUseCase(patients: patients),
            loadConditions: LoadConditionsUseCase(conditions: conditions),
            loadEntries: LoadEntriesUseCase(entries: entries)
        )
    }

    /// Production wiring: every repository is backed by the on-device SwiftData store.
    static func swiftData(container: ModelContainer) -> AppEnvironment {
        let store = SwiftDataCareStore(modelContainer: container)
        return make(patients: store, conditions: store, entries: store)
    }

    /// Previews and tests only; nothing is saved between launches.
    static func inMemory() -> AppEnvironment {
        let store = InMemoryCareStore()
        return make(patients: store, conditions: store, entries: store)
    }
}
