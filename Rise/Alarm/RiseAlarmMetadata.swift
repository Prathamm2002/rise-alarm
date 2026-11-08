//
//  RiseAlarmMetadata.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import AlarmKit
import Foundation

/// Metadata attached to every AlarmKit alarm Rise schedules. `Alarm` does not
/// expose attributes back to the app, so mapping AlarmKit IDs to Rise alarms
/// goes through `ScheduleIndex`; this exists because the generic type needs it.
nonisolated struct RiseAlarmMetadata: AlarmMetadata {
    enum Kind: String, Codable, Hashable, Sendable {
        case main, nag
    }

    var riseAlarmID: UUID
    var kind: Kind
}
