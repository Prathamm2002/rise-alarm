//
//  StartMissionIntent.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import AlarmKit
import AppIntents
import Foundation

/// Secondary ("Start Mission") button on the alarm alert. Opens Rise straight
/// into the mission. Never throws: a throwing secondary intent can leave an
/// alarm alerting with no controls.
struct StartMissionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Start Mission" }
    static var description: IntentDescription? {
        IntentDescription("Opens Rise straight into your wake-up mission.")
    }
    /// Deprecated on iOS 26 in favour of `supportedModes`; kept per plan and
    /// mirrored by `supportedModes` below.
    static var openAppWhenRun: Bool { true }
    static var supportedModes: IntentModes { .foreground(.immediate) }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        let id = alarmID
        await MainActor.run {
            AppModel.shared.handleStartMissionIntent(alarmKitID: id)
        }
        return .result()
    }
}
