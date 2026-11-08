//
//  AlarmStore.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation
import Observation

/// Persists the user's alarms as JSON in `UserDefaults.standard`.
@MainActor
@Observable
final class AlarmStore {
    private static let key = "rise.alarms.v1"

    private(set) var alarms: [RiseAlarm] = []

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func alarm(id: UUID) -> RiseAlarm? {
        alarms.first { $0.id == id }
    }

    func upsert(_ alarm: RiseAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        sortAndSave()
    }

    func delete(id: UUID) {
        alarms.removeAll { $0.id == id }
        sortAndSave()
    }

    func update(id: UUID, _ mutate: (inout RiseAlarm) -> Void) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        mutate(&alarms[index])
        sortAndSave()
    }

    private func sortAndSave() {
        alarms.sort { ($0.hour, $0.minute, $0.id.uuidString) < ($1.hour, $1.minute, $1.id.uuidString) }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.key) else { return }
        do {
            alarms = try JSONDecoder().decode([RiseAlarm].self, from: data)
            alarms.sort { ($0.hour, $0.minute, $0.id.uuidString) < ($1.hour, $1.minute, $1.id.uuidString) }
        } catch {
            print("Rise: could not decode alarms: \(error)")
        }
    }

    private func save() {
        do {
            defaults.set(try JSONEncoder().encode(alarms), forKey: Self.key)
        } catch {
            print("Rise: could not encode alarms: \(error)")
        }
    }
}
