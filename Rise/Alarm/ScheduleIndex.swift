//
//  ScheduleIndex.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// One backup alarm scheduled with AlarmKit.
struct ScheduledNag: Codable, Hashable, Sendable {
    var alarmKitID: UUID
    var riseAlarmID: UUID
    var occurrence: Date
    var fireDate: Date
    var ordinal: Int
}

/// Maps AlarmKit IDs back to Rise alarms. Main alarms share the Rise alarm's ID;
/// nags are recorded here. Persisted in `UserDefaults.standard`.
@MainActor
final class ScheduleIndex {
    private static let key = "rise.index.v1"

    private(set) var entries: [ScheduledNag] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([ScheduledNag].self, from: data) {
            entries = decoded
        }
    }

    func riseAlarmID(for alarmKitID: UUID, store: AlarmStore) -> UUID? {
        if store.alarm(id: alarmKitID) != nil { return alarmKitID }
        return nag(alarmKitID)?.riseAlarmID
    }

    func nag(_ alarmKitID: UUID) -> ScheduledNag? {
        entries.first { $0.alarmKitID == alarmKitID }
    }

    func nags(for riseID: UUID) -> [ScheduledNag] {
        entries.filter { $0.riseAlarmID == riseID }
    }

    func contains(_ alarmKitID: UUID) -> Bool {
        entries.contains { $0.alarmKitID == alarmKitID }
    }

    func add(_ nag: ScheduledNag) {
        entries.removeAll { $0.alarmKitID == nag.alarmKitID }
        entries.append(nag)
        save()
    }

    func remove(alarmKitIDs: Set<UUID>) {
        guard !alarmKitIDs.isEmpty else { return }
        entries.removeAll { alarmKitIDs.contains($0.alarmKitID) }
        save()
    }

    func removeAll(where predicate: (ScheduledNag) -> Bool) {
        let before = entries.count
        entries.removeAll(where: predicate)
        if entries.count != before { save() }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
