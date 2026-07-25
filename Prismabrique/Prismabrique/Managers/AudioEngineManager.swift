import AVFoundation

/// Minimal programmatic tone-generation audio engine (mirrors the original web project's
/// `audio.js` approach) so Prismabrique ships with zero bundled audio assets or third-party
/// dependencies. All frequencies/durations/volumes are supplied by callers from
/// `GameBalanceConfig.audio` — this file only knows how to synthesize a sine-wave beep.
final class AudioEngineManager {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var isRunning = false

    init() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
    }

    private func ensureRunning() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            // Audio is a non-critical enhancement; failing silently keeps gameplay usable
            // (e.g. when running with no audio hardware or interrupted by a phone call).
            isRunning = false
        }
    }

    func playTone(frequency: Double, duration: Double, volume: Double) {
        ensureRunning()
        guard isRunning else { return }

        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let channelData = buffer.floatChannelData?[0]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // Simple exponential decay envelope avoids audible clicks at the tail.
            let envelope = exp(-4.0 * t / duration)
            let sample = sin(2.0 * .pi * frequency * t) * envelope * volume
            channelData?[frame] = Float(sample)
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: format)
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            self?.engine.detach(player)
        }
        player.play()
    }
}

/// Process-wide façade so gameplay code (`GameEngine`, which is not a SwiftUI view) can
/// trigger sound without holding a reference to the underlying engine. Honors the player's
/// sound setting from `PersistenceStore`.
enum AudioBridge {
    static let shared = AudioEngineManager()
    static var isEnabled = true

    static func playTone(frequency: Double, duration: Double, volume: Double) {
        guard isEnabled else { return }
        shared.playTone(frequency: frequency, duration: duration, volume: volume)
    }
}
