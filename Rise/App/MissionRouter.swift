//
//  MissionRouter.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation
import Observation

struct ActiveMission: Identifiable, Sendable, Equatable {
    let id = UUID()
    let riseAlarmID: UUID?
    let occurrence: Date?
    let label: String
    let config: MissionConfig
    let isPractice: Bool
}

@MainActor
@Observable
final class MissionRouter {
    var active: ActiveMission?
}
