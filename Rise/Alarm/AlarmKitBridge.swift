//
//  AlarmKitBridge.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import AlarmKit
import Foundation
import SwiftUI

/// Plain, Sendable view of an AlarmKit alarm so the rest of the app never
/// needs to import AlarmKit.
struct AlarmSnapshot: Sendable, Hashable {
    enum State: Sendable, Hashable {
        case scheduled, countdown, paused, alerting
    }

    let id: UUID
    let state: State

    var isAlerting: Bool { state == .alerting }
}

/// Rise's view of the AlarmKit permission.
enum AlarmAuthorization: Sendable, Equatable {
    case notDetermined, denied, authorized
}

/// The ONLY place that builds AlarmKit configurations or talks to `AlarmManager`.
///
/// Nonisolated on purpose: `AlarmManager` is a non-Sendable class, so its async
/// methods are called from nonisolated async functions here (no value crosses an
/// isolation boundary). Callers on the main actor only pass Sendable values in.
enum AlarmKitBridge {
    // MARK: Authorization

    static func requestAuthorization() async -> AlarmAuthorization {
        let manager = AlarmManager.shared
        do {
            return map(try await manager.requestAuthorization())
        } catch {
            print("Rise: AlarmKit authorization failed: \(error)")
            return map(manager.authorizationState)
        }
    }

    static var authorization: AlarmAuthorization {
        map(AlarmManager.shared.authorizationState)
    }

    static var isAuthorized: Bool { authorization == .authorized }

    // MARK: Scheduling

    /// Main alarm: id == RiseAlarm.id, AlarmKit's own relative schedule.
    static func scheduleMain(_ alarm: RiseAlarm) async throws {
        let repeats: Alarm.Schedule.Relative.Recurrence = alarm.weekdays.isEmpty
            ? .never
            : .weekly(alarm.weekdays.sorted { $0.rawValue < $1.rawValue }.map(\.localeWeekday))
        let schedule = Alarm.Schedule.relative(
            .init(time: .init(hour: alarm.hour, minute: alarm.minute), repeats: repeats))
        let config = configuration(schedule: schedule,
                                   title: alarm.label.isEmpty ? "Rise: time to get up" : alarm.label,
                                   riseID: alarm.id, kind: .main, alarmKitID: alarm.id)
        _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: config)
    }

    /// One-shot backup alarm at a fixed date.
    static func scheduleNag(id: UUID, at date: Date, for alarm: RiseAlarm, ordinal: Int, total: Int) async throws {
        let config = configuration(schedule: .fixed(date),
                                   title: "Rise: mission not done (\(ordinal)/\(total))",
                                   riseID: alarm.id, kind: .nag, alarmKitID: id)
        _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
    }

    static func cancel(_ id: UUID) {
        do {
            try AlarmManager.shared.cancel(id: id)
        } catch {
            // Not scheduled any more: nothing to do.
        }
    }

    static func stop(_ id: UUID) {
        do {
            try AlarmManager.shared.stop(id: id)
        } catch {
            // Not alerting: nothing to do.
        }
    }

    /// Stops `id` only if AlarmKit reports it alerting (or if the list cannot be
    /// read). Calling `stop` on a merely *scheduled* repeating alarm has
    /// unverified semantics and could skip its next occurrence, so avoid it.
    static func stopIfAlerting(_ id: UUID) {
        if let live = currentAlarms(), let match = live.first(where: { $0.id == id }), !match.isAlerting {
            return
        }
        stop(id)
    }

    /// Current AlarmKit alarms, or nil if AlarmKit could not be read
    /// (callers must not treat that as "no alarms").
    static func currentAlarms() -> [AlarmSnapshot]? {
        do {
            return try AlarmManager.shared.alarms.map(snapshot)
        } catch {
            print("Rise: could not read AlarmKit alarms: \(error)")
            return nil
        }
    }

    /// Runs until the calling task is cancelled.
    static func observeUpdates(_ handler: @escaping @Sendable ([AlarmSnapshot]) async -> Void) async {
        for await alarms in AlarmManager.shared.alarmUpdates {
            if Task.isCancelled { return }
            await handler(alarms.map(snapshot))
        }
    }

    static func isLimitError(_ error: any Error) -> Bool {
        (error as? AlarmManager.AlarmError) == .maximumLimitReached
    }

    // MARK: Private

    private static func configuration(schedule: Alarm.Schedule, title: String, riseID: UUID,
                                      kind: RiseAlarmMetadata.Kind,
                                      alarmKitID: UUID) -> AlarmManager.AlarmConfiguration<RiseAlarmMetadata> {
        let mission = AlarmButton(text: "Start Mission", textColor: .black, systemImageName: "brain.head.profile")
        let alert = makeAlert(title: LocalizedStringResource(stringLiteral: title), secondaryButton: mission)
        let attributes = AlarmAttributes<RiseAlarmMetadata>(presentation: AlarmPresentation(alert: alert),
                                                            metadata: RiseAlarmMetadata(riseAlarmID: riseID, kind: kind),
                                                            tintColor: Theme.accent)
        return AlarmManager.AlarmConfiguration<RiseAlarmMetadata>(
            countdownDuration: nil,
            schedule: schedule,
            attributes: attributes,
            stopIntent: RiseStopIntent(alarmID: alarmKitID.uuidString),
            secondaryIntent: StartMissionIntent(alarmID: alarmKitID.uuidString))
        // `sound:` left at its default (ActivityKit `.default`).
    }

    /// SDK 26.5 dump: `init(title:secondaryButton:secondaryButtonBehavior:)` is
    /// iOS 26.1+, and the `stopButton:` form is deprecated from 26.1. Use the new
    /// one where available and the old one only on 26.0.
    private static func makeAlert(title: LocalizedStringResource,
                                  secondaryButton: AlarmButton) -> AlarmPresentation.Alert {
        if #available(iOS 26.1, *) {
            return AlarmPresentation.Alert(title: title,
                                           secondaryButton: secondaryButton,
                                           secondaryButtonBehavior: .custom)
        } else {
            let stop = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill")
            return AlarmPresentation.Alert(title: title,
                                           stopButton: stop,
                                           secondaryButton: secondaryButton,
                                           secondaryButtonBehavior: .custom)
        }
    }

    private static func map(_ state: AlarmManager.AuthorizationState) -> AlarmAuthorization {
        switch state {
        case .authorized: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    private static func snapshot(_ alarm: Alarm) -> AlarmSnapshot {
        let state: AlarmSnapshot.State
        switch alarm.state {
        case .scheduled: state = .scheduled
        case .countdown: state = .countdown
        case .paused: state = .paused
        case .alerting: state = .alerting
        @unknown default: state = .scheduled
        }
        return AlarmSnapshot(id: alarm.id, state: state)
    }
}
