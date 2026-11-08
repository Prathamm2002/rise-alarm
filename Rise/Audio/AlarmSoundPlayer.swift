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

    var isPlaying: Bool { player?.isPlaying ?? false }

    func start() {
        guard !isPlaying else { return }
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

    func stop() {
        player?.stop()
        player = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Rise: audio session deactivate error: \(error)")
        }
    }
}
