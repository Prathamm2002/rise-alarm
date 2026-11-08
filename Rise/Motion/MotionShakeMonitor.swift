//
//  MotionShakeMonitor.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import CoreMotion
import Foundation
import Observation

/// Feeds accelerometer samples into a `ShakeDetector` on the main actor.
@MainActor
@Observable
final class MotionShakeMonitor {
    private(set) var count = 0
    private(set) var target = 0
    let isAvailable: Bool

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var detector = ShakeDetector()
    @ObservationIgnored private var onReachedTarget: (@MainActor () -> Void)?

    init() {
        isAvailable = manager.isAccelerometerAvailable
        manager.accelerometerUpdateInterval = 1.0 / 50.0
    }

    var isCompleted: Bool { target > 0 && count >= target }

    func start(target: Int, onReachedTarget: @escaping @MainActor () -> Void) {
        self.target = target
        self.onReachedTarget = onReachedTarget
        detector.reset()
        count = 0
        guard isAvailable, !manager.isAccelerometerActive else { return }
        // Handler runs on the main queue; copy plain values out before hopping
        // so no CMAccelerometerData crosses isolation.
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let t = data.timestamp
            MainActor.assumeIsolated {
                self?.ingest(x: x, y: y, z: z, t: t)
            }
        }
    }

    func stop() {
        if manager.isAccelerometerActive {
            manager.stopAccelerometerUpdates()
        }
        onReachedTarget = nil
    }

    /// Practice-mode helper for devices without an accelerometer (simulator).
    func simulateShake() {
        registerShake()
    }

    private func ingest(x: Double, y: Double, z: Double, t: TimeInterval) {
        guard !isCompleted else { return }
        if detector.process(x: x, y: y, z: z, at: t) {
            registerShake()
        }
    }

    private func registerShake() {
        guard !isCompleted else { return }
        count += 1
        if isCompleted {
            let callback = onReachedTarget
            stop()
            callback?()
        }
    }
}
