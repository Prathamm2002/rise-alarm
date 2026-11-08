//
//  RiseStopIntent.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import AlarmKit
import AppIntents
import Foundation

/// System Stop control on the alarm alert. Silences only that alert: the
/// pre-scheduled backup alarms keep ringing until the mission is done.
/// Never throws.
struct RiseStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop Alarm" }
    static var description: IntentDescription? {
        IntentDescription("Silences the current Rise alert. Backup alarms continue until the mission is done.")
    }
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
        let model = await MainActor.run { AppModel.shared }
        await model.handleStopIntent(alarmKitID: id)
        return .result()
    }
}
