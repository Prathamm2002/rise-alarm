//
//  RiseApp.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI

@main
struct RiseApp: App {
    @State private var model = AppModel.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                AlarmListView()
                // Real missions are a root-level overlay rather than a
                // fullScreenCover so they can never be blocked by the editor
                // sheet; there is no way to swipe or close them.
                if let mission = model.router.active {
                    MissionView(mission: mission) { model.dismissMission() }
                        .id(mission.id)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: model.router.active?.id)
            .environment(model)
            .preferredColorScheme(.dark)
            .tint(Theme.accent)
            .task {
                if !AppEnvironment.isRunningTests {
                    await model.bootstrap()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, !AppEnvironment.isRunningTests else { return }
                Task { await model.sceneBecameActive() }
            }
        }
    }
}
