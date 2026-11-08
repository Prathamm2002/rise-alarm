//
//  AlarmMonitor.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// Forwards AlarmKit's `alarmUpdates` stream to the main actor.
/// The stream itself is consumed inside `AlarmKitBridge` (nonisolated); only
/// Sendable snapshots cross to the main actor.
@MainActor
final class AlarmMonitor {
    private var task: Task<Void, Never>?

    var isRunning: Bool { task != nil }

    func start(_ onUpdate: @escaping @MainActor @Sendable ([AlarmSnapshot]) -> Void) {
        task?.cancel()
        task = Task {
            await AlarmKitBridge.observeUpdates { snapshots in
                await onUpdate(snapshots)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
