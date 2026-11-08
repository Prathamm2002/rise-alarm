//
//  ToneGenerator.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

/// Builds a 16-bit mono PCM WAV of alarm beeps in memory (no bundled audio).
enum ToneGenerator {
    static func alarmWAV(sampleRate: Int = 44_100,
                         frequency: Double = 880,
                         beepDuration: Double = 0.18,
                         gap: Double = 0.08,
                         beepsPerBurst: Int = 4,
                         pause: Double = 0.5,
                         amplitude: Double = 0.9) -> Data {
        let beepSamples = max(1, Int(beepDuration * Double(sampleRate)))
        let gapSamples = max(0, Int(gap * Double(sampleRate)))
        let pauseSamples = max(0, Int(pause * Double(sampleRate)))
        let fadeSamples = max(1, min(beepSamples / 2, Int(0.005 * Double(sampleRate))))
        let peak = Double(Int16.max) * min(max(amplitude, 0), 1)

        var samples: [Int16] = []
        samples.reserveCapacity(beepsPerBurst * (beepSamples + gapSamples) + pauseSamples)
        for beep in 0..<max(1, beepsPerBurst) {
            for i in 0..<beepSamples {
                let t = Double(i) / Double(sampleRate)
                var envelope = 1.0
                if i < fadeSamples { envelope = Double(i) / Double(fadeSamples) }
                let fromEnd = beepSamples - 1 - i
                if fromEnd < fadeSamples { envelope = min(envelope, Double(fromEnd) / Double(fadeSamples)) }
                let value = sin(2 * .pi * frequency * t) * peak * envelope
                samples.append(Int16(max(min(value, Double(Int16.max)), Double(Int16.min))))
            }
            if beep < beepsPerBurst - 1 {
                samples.append(contentsOf: repeatElement(0, count: gapSamples))
            }
        }
        samples.append(contentsOf: repeatElement(0, count: pauseSamples))

        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let blockAlign = channels * bitsPerSample / 8
        let byteRate = UInt32(sampleRate) * UInt32(blockAlign)
        let dataSize = UInt32(samples.count) * UInt32(blockAlign)

        var data = Data()
        data.reserveCapacity(44 + Int(dataSize))
        data.append(contentsOf: Array("RIFF".utf8))
        data.appendLE(UInt32(36) + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        data.appendLE(UInt32(16))          // PCM fmt chunk size
        data.appendLE(UInt16(1))           // PCM format
        data.appendLE(channels)
        data.appendLE(UInt32(sampleRate))
        data.appendLE(byteRate)
        data.appendLE(blockAlign)
        data.appendLE(bitsPerSample)
        data.append(contentsOf: Array("data".utf8))
        data.appendLE(dataSize)
        for sample in samples {
            data.appendLE(UInt16(bitPattern: sample))
        }
        return data
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }
}
