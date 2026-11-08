//
//  AppEnvironment.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import Foundation

enum AppEnvironment {
    /// True when the app is hosting the unit-test bundle. The test host must never
    /// request AlarmKit authorization or schedule anything.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
