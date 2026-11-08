//
//  PermissionBanner.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import SwiftUI
import UIKit

/// Shown while AlarmKit permission is missing.
struct PermissionBanner: View {
    let authorization: AlarmAuthorization
    let onAllow: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "alarm.waves.left.and.right")
                .font(.title2)
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 8) {
                Text("Alarms are off")
                    .font(.headline)
                Text(authorization == .denied
                     ? "Rise is not allowed to schedule alarms. Turn on Alarms for Rise in Settings so your alarms ring."
                     : "Allow Rise to schedule alarms so they ring through Silent mode and Focus.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if authorization == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                } else {
                    Button("Allow", action: onAllow)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                }
            }
            Spacer(minLength: 0)
        }
        .riseCard(Theme.accentSoft)
    }
}

/// Dismissible error banner.
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.danger)
            Text(message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .accessibilityLabel("Dismiss")
        }
        .riseCard(Theme.danger.opacity(0.15))
    }
}
