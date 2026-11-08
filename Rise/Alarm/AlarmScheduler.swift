//
//  AlarmScheduler.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation
import Observation

/// Keeps AlarmKit in step with the store: one main alarm per enabled Rise alarm
/// plus up to `policy.count` one-shot nags for the next or active occurrence.
///
/// All public operations are serialised so overlapping triggers (launch,
/// foreground, intents, completion) never double-schedule nags.
@MainActor
@Observable
final class AlarmScheduler {
    private(set) var lastError: String?

    @ObservationIgnored private let store: AlarmStore
    @ObservationIgnored private let index: ScheduleIndex
    @ObservationIgnored private let policy: NagPolicy
    @ObservationIgnored private var tail: Task<Void, Never>?
    @ObservationIgnored var isAuthorized: () -> Bool = { AlarmKitBridge.isAuthorized }

    init(store: AlarmStore, index: ScheduleIndex, policy: NagPolicy = .standard) {
        self.store = store
        self.index = index
        self.policy = policy
    }

    func clearError() { lastError = nil }

    // MARK: Public operations

    /// Cancel the alarm's main + nags; if enabled and authorized, schedule again.
    func sync(_ alarm: RiseAlarm) async {
        await serialized { scheduler in
            scheduler.cancelEverything(for: alarm.id)
            guard alarm.isEnabled, scheduler.isAuthorized() else { return }
            let now = Date.now
            if await scheduler.scheduleMain(alarm) {
                await scheduler.ensureNags(for: alarm, now: now)
            }
        }
    }

    /// Cancel main + nags and drop their index entries.
    func remove(riseID: UUID) async {
        await serialized { scheduler in
            scheduler.cancelEverything(for: riseID)
        }
    }

    func reconcile(now: Date? = nil) async {
        await serialized { scheduler in
            await scheduler.performReconcile(now: now ?? .now)
        }
    }

    func completeMission(riseID: UUID, occurrence: Date) async {
        await serialized { scheduler in
            scheduler.store.update(id: riseID) { alarm in
                if alarm.lastCompletedOccurrence.map({ $0 < occurrence }) ?? true {
                    alarm.lastCompletedOccurrence = occurrence
                }
            }
            // Stop + cancel this occurrence's nags.
            let nags = scheduler.index.nags(for: riseID).filter { $0.occurrence == occurrence }
            for nag in nags {
                AlarmKitBridge.stop(nag.alarmKitID)
                AlarmKitBridge.cancel(nag.alarmKitID)
            }
            scheduler.index.remove(alarmKitIDs: Set(nags.map(\.alarmKitID)))
            // Stop (never cancel) a repeating main alarm in case it is still alerting.
            AlarmKitBridge.stop(riseID)
            if let alarm = scheduler.store.alarm(id: riseID), !alarm.isRepeating {
                scheduler.store.update(id: riseID) { $0.isEnabled = false }
                scheduler.cancelEverything(for: riseID)
            }
            await scheduler.performReconcile(now: .now)
        }
    }

    // MARK: Serialisation

    private func serialized(_ operation: @escaping @MainActor @Sendable (AlarmScheduler) async -> Void) async {
        let previous = tail
        let task = Task { @MainActor [self] in
            await previous?.value
            await operation(self)
        }
        tail = task
        await task.value
    }

    // MARK: Reconcile

    private func performReconcile(now: Date) async {
        guard isAuthorized() else { return }
        guard let live = AlarmKitBridge.currentAlarms() else { return }
        let liveIDs = Set(live.map(\.id))
        let storeIDs = Set(store.alarms.map(\.id))

        // 1. Orphans: live AlarmKit alarms Rise does not know about.
        for id in liveIDs where !storeIDs.contains(id) && !index.contains(id) {
            AlarmKitBridge.cancel(id)
        }
        // 2. Index entries AlarmKit no longer holds (fired, stopped or dropped).
        //    Future ones are re-added by ensureNags below.
        index.removeAll { !liveIDs.contains($0.alarmKitID) }
        // Index entries for Rise alarms that no longer exist.
        let strays = index.entries.filter { !storeIDs.contains($0.riseAlarmID) }
        for nag in strays { AlarmKitBridge.cancel(nag.alarmKitID) }
        index.remove(alarmKitIDs: Set(strays.map(\.alarmKitID)))

        // 3. Per alarm.
        for alarm in store.alarms {
            guard alarm.isEnabled else {
                cancelEverything(for: alarm.id)
                continue
            }
            let active = alarm.activeOccurrence(now: now, policy: policy)

            // A one-time alarm that has already fired (missed or finished) is done.
            if !alarm.isRepeating, active == nil,
               let previous = alarm.previousFireDate(onOrBefore: now), previous > alarm.armedSince {
                store.update(id: alarm.id) { $0.isEnabled = false }
                cancelEverything(for: alarm.id)
                continue
            }

            // Never reschedule a live main alarm: it may be alerting.
            if !liveIDs.contains(alarm.id), active == nil {
                guard await scheduleMain(alarm) else { continue }
            }
            await ensureNags(for: alarm, now: now)
        }
    }

    // MARK: Helpers

    @discardableResult
    private func scheduleMain(_ alarm: RiseAlarm) async -> Bool {
        do {
            try await AlarmKitBridge.scheduleMain(alarm)
            return true
        } catch {
            report(error, context: "Could not schedule \(alarm.displayLabel)")
            return false
        }
    }

    private func ensureNags(for alarm: RiseAlarm, now: Date) async {
        let existing = index.nags(for: alarm.id)
        guard let target = alarm.nagTargetOccurrence(now: now, policy: policy) else {
            cancel(existing)
            return
        }
        cancel(existing.filter { $0.occurrence != target })

        let have = Set(existing.filter { $0.occurrence == target }.map(\.ordinal))
        let dates = NagChain.dates(occurrence: target, policy: policy)
        for (offset, date) in dates.enumerated() {
            let ordinal = offset + 1
            guard date > now, !have.contains(ordinal) else { continue }
            let id = UUID()
            do {
                try await AlarmKitBridge.scheduleNag(id: id, at: date, for: alarm, ordinal: ordinal, total: policy.count)
                index.add(ScheduledNag(alarmKitID: id, riseAlarmID: alarm.id, occurrence: target,
                                       fireDate: date, ordinal: ordinal))
            } catch {
                if AlarmKitBridge.isLimitError(error) {
                    lastError = "iOS alarm limit reached: some backup alarms for \(alarm.displayLabel) were skipped. Turn off alarms you do not need."
                } else {
                    report(error, context: "Could not schedule backup alarms")
                }
                return
            }
        }
    }

    private func cancel(_ nags: [ScheduledNag]) {
        guard !nags.isEmpty else { return }
        for nag in nags { AlarmKitBridge.cancel(nag.alarmKitID) }
        index.remove(alarmKitIDs: Set(nags.map(\.alarmKitID)))
    }

    private func cancelEverything(for riseID: UUID) {
        AlarmKitBridge.cancel(riseID)
        cancel(index.nags(for: riseID))
    }

    private func report(_ error: any Error, context: String) {
        print("Rise: \(context): \(error)")
        lastError = "\(context). \(error.localizedDescription)"
    }
}
