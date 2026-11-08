//
//  ShakeDetector.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// Counts shakes from raw accelerometer samples (in g, gravity included),
/// debounced by `minInterval`.
struct ShakeDetector: Sendable {
    var threshold: Double = 2.0
    var minInterval: TimeInterval = 0.3
    private(set) var count = 0
    private var lastShakeTime: TimeInterval?

    init(threshold: Double = 2.0, minInterval: TimeInterval = 0.3) {
        self.threshold = threshold
        self.minInterval = minInterval
    }

    /// Returns true when this sample counts as a new shake.
    mutating func process(x: Double, y: Double, z: Double, at t: TimeInterval) -> Bool {
        let magnitude = (x * x + y * y + z * z).squareRoot()
        guard magnitude >= threshold else { return false }
        if let lastShakeTime, t - lastShakeTime < minInterval { return false }
        lastShakeTime = t
        count += 1
        return true
    }

    mutating func reset() {
        count = 0
        lastShakeTime = nil
    }
}
