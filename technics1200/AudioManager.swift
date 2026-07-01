//
//  AudioManager.swift
//  technics1200
//
//  Drives MP3 playback with a turntable-style varispeed pitch control
//  (speed + pitch move together, just like a real Technics platter) and
//  exposes a smoothed audio level used to make the vinyl react to the music.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class AudioManager: ObservableObject {

    // MARK: Published UI state
    @Published var isPlaying = false
    @Published var hasTrack = false
    @Published var trackTitle = "NO DISC"
    /// Pitch fader value in percent, -8 ... +8 (Technics SL-1200 range).
    @Published var pitch: Double = 0
    /// Smoothed broadband level 0...1, drives the vinyl groove reaction.
    @Published var level: Double = 0
    /// Faster transient peak 0...1, used for accent flashes.
    @Published var peak: Double = 0
    /// Low / mid / high band energies 0...1 for richer visuals.
    @Published var bands: SIMD3<Double> = .zero

    // MARK: Engine
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let varispeed = AVAudioUnitVarispeed()
    private var file: AVAudioFile?
    private var scopedURL: URL?

    // MARK: Platter rotation (plain vars — advanced from the TimelineView clock)
    /// Current platter angle in degrees.
    private(set) var platterAngle: Double = 0
    /// Eased rotational speed as a fraction of nominal (0 = stopped, 1 = full).
    private(set) var platterSpeed: Double = 0
    private var lastTick: Date?
    /// Cached playback progress 0...1 for the tonearm tracking.
    private(set) var progress: Double = 0

    /// 33 1/3 RPM expressed in degrees per second.
    private let degreesPerSecond = 200.0

    /// Playback rate multiplier from the pitch fader.
    var rate: Double { 1.0 + pitch / 100.0 }

    init() {
        configureSession()
        setupEngine()
    }

    // MARK: - Setup

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        #endif
    }

    private func setupEngine() {
        engine.attach(player)
        engine.attach(varispeed)
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(player, to: varispeed, format: format)
        engine.connect(varispeed, to: engine.mainMixerNode, format: format)
        installTap()
    }

    private func installTap() {
        let mixer = engine.mainMixerNode
        mixer.removeTap(onBus: 0)
        let format = mixer.outputFormat(forBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let (rms, pk, bands) = AudioManager.analyze(buffer)
            Task { @MainActor in
                self.ingest(rms: rms, peak: pk, bands: bands)
            }
        }
    }

    /// Smooths incoming level data with a fast attack / slow release envelope.
    private func ingest(rms: Double, peak pk: Double, bands newBands: SIMD3<Double>) {
        let attack = 0.55
        let release = 0.12
        func env(_ current: Double, _ target: Double) -> Double {
            let c = target > current ? attack : release
            return current + (target - current) * c
        }
        level = env(level, rms)
        peak = max(pk, peak * 0.86)
        bands = SIMD3(env(bands.x, newBands.x),
                      env(bands.y, newBands.y),
                      env(bands.z, newBands.z))
    }

    /// Computes RMS, peak and three crude frequency bands from a buffer.
    nonisolated private static func analyze(_ buffer: AVAudioPCMBuffer) -> (Double, Double, SIMD3<Double>) {
        guard let channels = buffer.floatChannelData else { return (0, 0, .zero) }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return (0, 0, .zero) }
        let channelCount = Int(buffer.format.channelCount)

        var sumSq = 0.0
        var peak = 0.0
        // Crude band splitting via simple running low-pass / difference filters.
        var low = 0.0, lowEnergy = 0.0, midEnergy = 0.0, highEnergy = 0.0
        var prev = 0.0

        for ch in 0..<channelCount {
            let data = channels[ch]
            for i in 0..<frames {
                let s = Double(data[i])
                sumSq += s * s
                peak = max(peak, abs(s))
                low += (s - low) * 0.05            // low-pass
                let high = s - low                 // high-pass remainder
                let mid = low - prev               // band-ish
                prev = low * 0.5
                lowEnergy += low * low
                midEnergy += mid * mid
                highEnergy += high * high
            }
        }

        let n = Double(frames * max(channelCount, 1))
        let rms = (sumSq / n).squareRoot()
        func norm(_ e: Double) -> Double { min(1.0, (e / n).squareRoot() * 4.0) }
        // Perceptual-ish lift so quiet passages still register subtly.
        let shaped = min(1.0, pow(rms * 3.2, 0.7))
        return (shaped, min(1.0, peak), SIMD3(norm(lowEnergy), norm(midEnergy), norm(highEnergy)))
    }

    // MARK: - Loading

    func load(url: URL) {
        stop()
        scopedURL?.stopAccessingSecurityScopedResource()
        let scoped = url.startAccessingSecurityScopedResource()
        scopedURL = scoped ? url : nil
        do {
            let f = try AVAudioFile(forReading: url)
            file = f
            hasTrack = true
            trackTitle = url.deletingPathExtension().lastPathComponent.uppercased()
            progress = 0
            try startEngineIfNeeded()
            schedule(from: 0)
        } catch {
            hasTrack = false
            trackTitle = "READ ERROR"
            file = nil
        }
    }

    private func startEngineIfNeeded() throws {
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    private func schedule(from frame: AVAudioFramePosition) {
        guard let file else { return }
        player.stop()
        file.framePosition = frame
        player.scheduleFile(file, at: nil) { [weak self] in
            Task { @MainActor in self?.handlePlaybackEnded() }
        }
    }

    private func handlePlaybackEnded() {
        // Only treat as a real ending when we actually reached the end.
        guard isPlaying, progress > 0.98 else { return }
        isPlaying = false
        progress = 1
    }

    // MARK: - Transport

    func togglePlay() {
        guard hasTrack else { return }
        isPlaying ? pause() : play()
    }

    func play() {
        guard hasTrack else { return }
        do {
            try startEngineIfNeeded()
            if progress >= 0.999 { schedule(from: 0); progress = 0 }
            player.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func stop() {
        player.stop()
        isPlaying = false
        level = 0; peak = 0; bands = .zero
    }

    // MARK: - Pitch

    func setPitch(_ value: Double) {
        pitch = min(8, max(-8, value))
        varispeed.rate = Float(rate)
    }

    func resetPitch() { setPitch(0) }

    // MARK: - Frame clock (called by the view's TimelineView)

    /// Advances platter rotation + progress for the given frame time and
    /// returns the current platter angle in degrees.
    func tick(_ date: Date) -> Double {
        let dt: Double
        if let last = lastTick {
            dt = min(0.05, max(0, date.timeIntervalSince(last)))
        } else {
            dt = 0
        }
        lastTick = date

        // Ease platter speed toward target (spin-up / spin-down feel).
        let target = isPlaying ? rate : 0
        let k = isPlaying ? 1.8 : 3.2
        platterSpeed += (target - platterSpeed) * min(1, dt * k)
        if abs(platterSpeed - target) < 0.0008 { platterSpeed = target }

        platterAngle += platterSpeed * degreesPerSecond * dt
        if platterAngle > 360 { platterAngle.formTruncatingRemainder(dividingBy: 360) }

        refreshProgress()
        return platterAngle
    }

    private func refreshProgress() {
        guard let file, isPlaying,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime),
              file.length > 0 else { return }
        let played = Double(playerTime.sampleTime)
        let total = Double(file.length)
        if total > 0 { progress = min(1, max(0, played / total)) }
    }

    static var supportedTypes: [UTType] {
        [.mp3, .mpeg4Audio, .wav, .aiff, .audio]
    }
}
