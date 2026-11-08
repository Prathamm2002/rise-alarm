//
//  AlarmScheduler.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation
import Observation

/// Keeps AlarmKit in step with the store: one main alarm per enabled Rise alarm
/// plus up to `policy.count` one-shot nags for the next or active occurrence
/// and, for repeating alarms, for the occurrence after it too.
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
                await scheduler.ensureNags(for: [alarm], now: now)
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
            // Stop (never cancel) a repeating main alarm, but only if it is still alerting.
            AlarmKitBridge.stopIfAlerting(riseID)
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

        // 3. Per alarm: main alarm first, then nags for all of them together.
        var needNags: [RiseAlarm] = []
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
            needNags.append(alarm)
        }
        await ensureNags(for: needNags, now: now)
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

    private enum FillOutcome { case done, limitReached, failed }

    /// Pre-schedules nags for every alarm in `alarms`. The current or next
    /// occurrence of every alarm is filled first; the following occurrence of
    /// repeating alarms only after that, so AlarmKit's alarm limit can only
    /// ever cost next-day backups. If the limit blocks a current/next nag,
    /// following-occurrence nags (of any alarm) are dropped to make room.
    private func ensureNags(for alarms: [RiseAlarm], now: Date) async {
        var plans: [(alarm: RiseAlarm, targets: [Date])] = []
        for alarm in alarms {
            let targets = alarm.nagTargetOccurrences(now: now, policy: policy)
            cancel(index.nags(for: alarm.id).filter { !targets.contains($0.occurrence) })
            if !targets.isEmpty { plans.append((alarm: alarm, targets: targets)) }
        }

        for plan in plans {
            var outcome = await fillNags(for: plan.alarm, occurrence: plan.targets[0], now: now)
            if outcome == .limitReached, shedFollowingNags(now: now) {
                outcome = await fillNags(for: plan.alarm, occurrence: plan.targets[0], now: now)
            }
            if outcome == .limitReached {
                lastError = "iOS alarm limit reached: some backup alarms for \(plan.alarm.displayLabel) were skipped. Turn off alarms you do not need."
                return
            }
        }

        for plan in plans {
            for occurrence in plan.targets.dropFirst() {
                let outcome = await fillNags(for: plan.alarm, occurrence: occurrence, now: now)
                if outcome == .limitReached {
                    // Current/next backups are complete; these are retried on the next reconcile.
                    print("Rise: alarm limit reached, following-occurrence backups deferred")
                    return
                }
            }
        }
    }

    /// Schedules the missing future nags of one occurrence.
    private func fillNags(for alarm: RiseAlarm, occurrence: Date, now: Date) async -> FillOutcome {
        let have = Set(index.nags(for: alarm.id).filter { $0.occurrence == occurrence }.map(\.ordinal))
        let dates = NagChain.dates(occurrence: occurrence, policy: policy)
        for (offset, date) in dates.enumerated() {
            let ordinal = offset + 1
            guard date > now, !have.contains(ordinal) else { continue }
            let id = UUID()
            do {
                try await AlarmKitBridge.scheduleNag(id: id, at: date, for: alarm, ordinal: ordinal, total: policy.count)
                index.add(ScheduledNag(alarmKitID: id, riseAlarmID: alarm.id, occurrence: occurrence,
                                       fireDate: date, ordinal: ordinal))
            } catch {
                if AlarmKitBridge.isLimitError(error) { return .limitReached }
                report(error, context: "Could not schedule backup alarms")
                return .failed
            }
        }
        return .done
    }

    /// Cancels nags that belong to an occurrence later than their alarm's
    /// current/next one. Returns whether anything was freed.
    private func shedFollowingNags(now: Date) -> Bool {
        let extra = index.entries.filter { nag in
            guard let alarm = store.alarm(id: nag.riseAlarmID),
                  let primary = alarm.nagTargetOccurrence(now: now, policy: policy) else { return false }
            return nag.occurrence > primary
        }
        cancel(extra)
        return !extra.isEmpty
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
