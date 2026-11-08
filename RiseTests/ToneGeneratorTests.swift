//
//  ToneGeneratorTests.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import XCTest
@testable import Rise

final class ToneGeneratorTests: XCTestCase {
    private func uint32(_ data: Data, at offset: Int) -> UInt32 {
        let bytes = [UInt8](data[offset..<(offset + 4)])
        return UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
    }

    private func uint16(_ data: Data, at offset: Int) -> UInt16 {
        let bytes = [UInt8](data[offset..<(offset + 2)])
        return UInt16(bytes[0]) | UInt16(bytes[1]) << 8
    }

    func testHeader() {
        let data = ToneGenerator.alarmWAV()
        XCTAssertGreaterThan(data.count, 44)
        XCTAssertEqual(String(decoding: data[0..<4], as: UTF8.self), "RIFF")
        XCTAssertEqual(String(decoding: data[8..<12], as: UTF8.self), "WAVE")
        XCTAssertEqual(String(decoding: data[12..<16], as: UTF8.self), "fmt ")
        XCTAssertEqual(String(decoding: data[36..<40], as: UTF8.self), "data")
        XCTAssertEqual(uint16(data, at: 20), 1)       // PCM
        XCTAssertEqual(uint16(data, at: 22), 1)       // mono
        XCTAssertEqual(uint32(data, at: 24), 44_100)  // sample rate
        XCTAssertEqual(uint16(data, at: 34), 16)      // bits per sample
        XCTAssertEqual(Int(uint32(data, at: 40)), data.count - 44)
        XCTAssertEqual(Int(uint32(data, at: 4)), data.count - 8)
    }

    func testCustomSampleRateAndNonSilent() {
        let data = ToneGenerator.alarmWAV(sampleRate: 22_050)
        XCTAssertEqual(uint32(data, at: 24), 22_050)
        let samples = stride(from: 44, to: data.count - 1, by: 2).map { Int16(bitPattern: uint16(data, at: $0)) }
        XCTAssertTrue(samples.contains { abs(Int($0)) > 10_000 })
    }
}
