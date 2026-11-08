//
//  AppModel.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation
import Observation
import UIKit

/// App-wide coordinator. Intents reach it through `AppModel.shared` on the main actor.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    let store: AlarmStore
    let router = MissionRouter()
    let scheduler: AlarmScheduler
    private(set) var authorization: AlarmAuthorization = .notDetermined

    @ObservationIgnored let index: ScheduleIndex
    @ObservationIgnored let monitor = AlarmMonitor()
    @ObservationIgnored let sound = AlarmSoundPlayer()
    @ObservationIgnored private var bootstrapped = false
    @ObservationIgnored private var askedForAuthorization = false

    var authorized: Bool { authorization == .authorized }
    var lastError: String? { scheduler.lastError }

    init() {
        let store = AlarmStore()
        let index = ScheduleIndex()
        self.store = store
        self.index = index
        self.scheduler = AlarmScheduler(store: store, index: index)
    }

    // MARK: Lifecycle

    /// Auth request, monitor start, reconcile, pending-mission check.
    func bootstrap() async {
        guard !bootstrapped, !AppEnvironment.isRunningTests else { return }
        bootstrapped = true
        authorization = AlarmKitBridge.authorization
        if authorization == .notDetermined {
            await requestAuthorization()
        }
        startMonitorIfNeeded()
        await scheduler.reconcile()
        checkForPendingMission()
    }

    func sceneBecameActive() async {
        guard bootstrapped, !AppEnvironment.isRunningTests else { return }
        authorization = AlarmKitBridge.authorization
        startMonitorIfNeeded()
        await scheduler.reconcile()
        checkForPendingMission()
    }

    func requestAuthorization() async {
        askedForAuthorization = true
        authorization = await AlarmKitBridge.requestAuthorization()
        if authorized {
            startMonitorIfNeeded()
            await scheduler.reconcile()
        }
    }

    private func startMonitorIfNeeded() {
        guard authorized, !monitor.isRunning else { return }
        monitor.start { [weak self] snapshots in
            self?.handleAlarmUpdates(snapshots)
        }
    }

    // MARK: Intents

    func handleStartMissionIntent(alarmKitID: String) {
        guard !AppEnvironment.isRunningTests else { return }
        defer { Task { await scheduler.reconcile() } }
        guard let akID = UUID(uuidString: alarmKitID) else { return }
        guard let riseID = index.riseAlarmID(for: akID, store: store),
              let alarm = store.alarm(id: riseID),
              let occurrence = occurrenceForTappedAlert(akID: akID, alarm: alarm) else {
            // Stale alert (unknown or already completed): just silence it.
            AlarmKitBridge.stop(akID)
            return
        }
        AlarmKitBridge.stop(akID)
        presentMission(riseAlarmID: riseID, occurrence: occurrence)
    }

    /// Silences the tapped alert (never cancels): the pre-scheduled nags keep
    /// coming until the mission is completed.
    func handleStopIntent(alarmKitID: String) {
        guard !AppEnvironment.isRunningTests else { return }
        if let akID = UUID(uuidString: alarmKitID) {
            AlarmKitBridge.stop(akID)
        }
        Task { await scheduler.reconcile() }
    }

    private func occurrenceForTappedAlert(akID: UUID, alarm: RiseAlarm) -> Date? {
        if let active = alarm.activeOccurrence() { return active }
        // Fallback for an alert the resolver does not consider live.
        let candidate = index.nag(akID)?.occurrence ?? alarm.previousFireDate()
        guard let candidate else { return nil }
        if let done = alarm.lastCompletedOccurrence, candidate <= done { return nil }
        return candidate
    }

    // MARK: Alarm updates

    func handleAlarmUpdates(_ snapshots: [AlarmSnapshot]) {
        let alerting = snapshots.filter(\.isAlerting)
        guard !alerting.isEmpty else { return }
        let inForeground = UIApplication.shared.applicationState == .active

        for snapshot in alerting {
            guard let riseID = index.riseAlarmID(for: snapshot.id, store: store),
                  let alarm = store.alarm(id: riseID) else { continue }
            if let current = router.active {
                // In-app tone is already playing for this alarm: silence the system nag.
                if current.riseAlarmID == riseID, inForeground { AlarmKitBridge.stop(snapshot.id) }
                continue
            }
            guard inForeground else { continue }
            let occurrence = index.nag(snapshot.id)?.occurrence ?? alarm.activeOccurrence()
            if let occurrence {
                presentMission(riseAlarmID: riseID, occurrence: occurrence)
            }
        }
    }

    /// Present any unfinished occurrence (resolver over all enabled alarms).
    func checkForPendingMission() {
        guard router.active == nil else { return }
        let now = Date.now
        for alarm in store.alarms where alarm.isEnabled {
            if let occurrence = alarm.activeOccurrence(now: now) {
                presentMission(riseAlarmID: alarm.id, occurrence: occurrence)
                return
            }
        }
    }

    // MARK: Missions

    func presentMission(riseAlarmID: UUID, occurrence: Date) {
        guard let alarm = store.alarm(id: riseAlarmID) else { return }
        if let done = alarm.lastCompletedOccurrence, occurrence <= done { return }
        stopAlerting(riseID: riseAlarmID)
        if let current = router.active, current.riseAlarmID == riseAlarmID, current.occurrence == occurrence {
            return
        }
        guard router.active == nil else { return }
        router.active = ActiveMission(riseAlarmID: riseAlarmID, occurrence: occurrence,
                                      label: alarm.displayLabel, config: alarm.mission.normalized(),
                                      isPractice: false)
        sound.start()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    /// Mission solved: silence everything and update schedules. The mission view
    /// shows a short "Good morning" and then calls `dismissMission()`.
    func completeMission() {
        sound.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        guard let mission = router.active, !mission.isPractice,
              let riseID = mission.riseAlarmID, let occurrence = mission.occurrence else { return }
        // Persist completion immediately so a foreground check cannot re-present it.
        store.update(id: riseID) { alarm in
            if alarm.lastCompletedOccurrence.map({ $0 < occurrence }) ?? true {
                alarm.lastCompletedOccurrence = occurrence
            }
        }
        Task { await scheduler.completeMission(riseID: riseID, occurrence: occurrence) }
    }

    func dismissMission() {
        router.active = nil
        checkForPendingMission()
    }

    func practiceMission(_ config: MissionConfig, label: String) -> ActiveMission {
        ActiveMission(riseAlarmID: nil, occurrence: nil, label: label.isEmpty ? "Practice" : label,
                      config: config.normalized(), isPractice: true)
    }

    private func stopAlerting(riseID: UUID) {
        guard let live = AlarmKitBridge.currentAlarms() else {
            AlarmKitBridge.stop(riseID)
            return
        }
        for snapshot in live where snapshot.isAlerting {
            if index.riseAlarmID(for: snapshot.id, store: store) == riseID {
                AlarmKitBridge.stop(snapshot.id)
            }
        }
    }

    // MARK: CRUD

    func save(_ alarm: RiseAlarm) async {
        var alarm = alarm
        alarm.mission = alarm.mission.normalized()
        alarm.armedSince = .now
        store.upsert(alarm)
        await scheduler.sync(alarm)
    }

    func delete(id: UUID) async {
        store.delete(id: id)
        await scheduler.remove(riseID: id)
    }

    func setEnabled(id: UUID, _ enabled: Bool) async {
        store.update(id: id) { alarm in
            alarm.isEnabled = enabled
            if enabled { alarm.armedSince = .now }
        }
        guard let alarm = store.alarm(id: id) else { return }
        await scheduler.sync(alarm)
    }

    /// Next fire date across all enabled alarms.
    func nextAlarmDate(after date: Date = .now) -> (alarm: RiseAlarm, date: Date)? {
        store.alarms
            .filter(\.isEnabled)
            .compactMap { alarm -> (alarm: RiseAlarm, date: Date)? in
                guard let next = alarm.nextFireDate(after: date) else { return nil }
                return (alarm: alarm, date: next)
            }
            .min { $0.date < $1.date }
    }
}
