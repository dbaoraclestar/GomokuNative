import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let sampleRate: Double = 44100

    private init() {}

    private func playTone(frequency: Double, duration: Double, type: String = "sine", volume: Float = 0.15) {
        DispatchQueue.global(qos: .userInteractive).async {
            let frameCount = AVAudioFrameCount(self.sampleRate * duration)
            guard let format = AVAudioFormat(standardFormatWithSampleRate: self.sampleRate, channels: 1),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

            buffer.frameLength = frameCount
            guard let data = buffer.floatChannelData?[0] else { return }

            for i in 0..<Int(frameCount) {
                let t = Double(i) / self.sampleRate
                let envelope = Float(max(0.001, volume * Float(1.0 - t / duration)))
                let sample: Float
                switch type {
                case "triangle":
                    let phase = t * frequency
                    let frac = phase - floor(phase)
                    sample = envelope * Float(frac < 0.5 ? 4 * frac - 1 : 3 - 4 * frac)
                default:
                    sample = envelope * Float(sin(2.0 * .pi * frequency * t))
                }
                data[i] = sample
            }

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)

            do {
                try engine.start()
                player.play()
                player.scheduleBuffer(buffer) {
                    engine.stop()
                }
            } catch {}
        }
    }

    func playPlaceSound() {
        DispatchQueue.global(qos: .userInteractive).async {
            let duration = 0.12
            let sweepDuration = 0.08
            let startFreq = 800.0
            let endFreq = 400.0
            let volume: Float = 0.15
            let frameCount = AVAudioFrameCount(self.sampleRate * duration)
            guard let format = AVAudioFormat(standardFormatWithSampleRate: self.sampleRate, channels: 1),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

            buffer.frameLength = frameCount
            guard let data = buffer.floatChannelData?[0] else { return }

            var phase = 0.0
            for i in 0..<Int(frameCount) {
                let t = Double(i) / self.sampleRate
                let envelope = Float(max(0.001, Double(volume) * (1.0 - t / duration)))
                let freq: Double = t < sweepDuration
                    ? startFreq * pow(endFreq / startFreq, t / sweepDuration)
                    : endFreq
                phase += 2.0 * .pi * freq / self.sampleRate
                data[i] = envelope * Float(sin(phase))
            }

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            do {
                try engine.start()
                player.play()
                player.scheduleBuffer(buffer) { engine.stop() }
            } catch {}
        }
    }

    func playWinSound() {
        let notes: [(Double, Double)] = [(523, 0), (659, 0.15), (784, 0.30), (1047, 0.45)]
        for (freq, delay) in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTone(frequency: freq, duration: 0.35, volume: 0.18)
            }
        }
    }

    func playLoseSound() {
        let notes: [(Double, Double)] = [(400, 0), (350, 0.18), (300, 0.36), (220, 0.54)]
        for (freq, delay) in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playTone(frequency: freq, duration: 0.3, type: "triangle", volume: 0.15)
            }
        }
    }
}
