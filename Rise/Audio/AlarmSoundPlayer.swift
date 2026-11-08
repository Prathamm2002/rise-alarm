//
//  AlarmSoundPlayer.swift
//  Rise
//
//  Created by Pratham Motwaney on 08/11/2026.
//

import AVFoundation

/// Loops the generated alarm tone while a real mission is on screen.
/// `.playback` keeps it audible in Silent mode; `UIBackgroundModes: audio`
/// keeps it looping if the user leaves the app mid-mission.
@MainActor
final class AlarmSoundPlayer {
    private var player: AVAudioPlayer?
    private lazy var wav: Data = ToneGenerator.alarmWAV()
    /// True between `start()` and `stop()`, even while iOS has paused playback.
    private var wantsPlayback = false
    private var interruptionObserver: (any NSObjectProtocol)?

    var isPlaying: Bool { player?.isPlaying ?? false }

    func start() {
        wantsPlayback = true
        observeInterruptionsIfNeeded()
        guard !isPlaying else { return }
        startPlayback()
    }

    func stop() {
        wantsPlayback = false
        player?.stop()
        player = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Rise: audio session deactivate error: \(error)")
        }
    }

    /// Restarts the tone if a mission still wants it but iOS paused it, e.g.
    /// because a system alarm alert interrupted the audio session.
    func resumeIfNeeded() {
        guard wantsPlayback, !isPlaying else { return }
        player?.stop()
        player = nil
        startPlayback()
    }

    private func startPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Rise: audio session error: \(error)")
        }
        do {
            let player = try AVAudioPlayer(data: wav)
            player.numberOfLoops = -1
            player.volume = 1
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            print("Rise: could not start alarm tone: \(error)")
        }
    }

    private func observeInterruptionsIfNeeded() {
        guard interruptionObserver == nil else { return }
        // Handler runs on the main queue; read the plain value out before hopping.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard raw == AVAudioSession.InterruptionType.ended.rawValue else { return }
            MainActor.assumeIsolated {
                self?.resumeIfNeeded()
            }
        }
    }
}
