//
//  ContentView.swift
//  technics1200
//
//  Assembles the SL-1200 MK2 inspired deck: spinning platter + reactive vinyl
//  in the centre, START/STOP and the red stroboscope lamp bottom-left, the
//  ±8% pitch fader on the right, the S-shaped tonearm at the rear-right and a
//  pop-up target light.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audio = AudioManager()
    @State private var showImporter = false
    @State private var lightUp = false

    var body: some View {
        GeometryReader { outer in
            ZStack {
                // Room backdrop.
                RadialGradient(colors: [Color(white: 0.12), .black],
                               center: .center, startRadius: 10, endRadius: 700)
                    .ignoresSafeArea()

                deck(in: outer.size)
                    .aspectRatio(1.32, contentMode: .fit)
                    .padding(18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: AudioManager.supportedTypes,
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                audio.load(url: url)
            }
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 560)
        #endif
    }

    private func deck(in available: CGSize) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let platterD = min(h * 0.80, w * 0.58)
            let platterCenter = CGPoint(x: w * 0.40, y: h * 0.54)
            let recordRadius = platterD * 0.9 / 2 * 0.95

            ZStack {
                deckBody(w: w, h: h)

                // Spinning platter + reactive vinyl, plus the tonearm, both on
                // the same animation clock so they stay locked together.
                TimelineView(.animation) { timeline in
                    let angle = audio.tick(timeline.date)
                    ZStack {
                        PlatterView(diameter: platterD,
                                    angle: angle,
                                    level: audio.level,
                                    bands: audio.bands,
                                    title: audio.trackTitle)
                            .position(platterCenter)

                        ToneArmView(size: geo.size,
                                    engaged: audio.isPlaying,
                                    progress: audio.progress,
                                    platterCenter: platterCenter,
                                    recordRadius: recordRadius)
                    }
                }

                // --- Controls -------------------------------------------------
                VStack(spacing: 3) {
                    Text("STROBO")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.black.opacity(0.5))
                    StrobeLamp(active: audio.hasTrack)
                        .frame(width: w * 0.085, height: h * 0.045)
                }
                .position(x: w * 0.085, y: h * 0.70)

                StartStopButton(isPlaying: audio.isPlaying) { audio.togglePlay() }
                    .frame(width: w * 0.14, height: w * 0.14)
                    .position(x: w * 0.115, y: h * 0.87)

                speedDisplay
                    .position(x: w * 0.115, y: h * 0.18)

                pitchSection(w: w, h: h)

                VStack(spacing: 3) {
                    PopupLight(raised: lightUp) {
                        withAnimation { lightUp.toggle() }
                    }
                    .frame(width: w * 0.06, height: h * 0.16)
                    Text("LIGHT")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.black.opacity(0.5))
                }
                .position(x: w * 0.575, y: h * 0.13)
            }
            .frame(width: w, height: h)
        }
    }

    // MARK: Body / chrome

    private func deckBody(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Deck.bodyGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Deck.bodyEdge, lineWidth: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1).blur(radius: 0.5))
            .overlay(
                // Platter recess shadow.
                Circle()
                    .fill(.black.opacity(0.18))
                    .frame(width: min(h * 0.86, w * 0.62) + 24,
                           height: min(h * 0.86, w * 0.62) + 24)
                    .blur(radius: 10)
                    .position(x: w * 0.40, y: h * 0.52))
            .shadow(color: .black.opacity(0.7), radius: 24, y: 18)
    }

    private var speedDisplay: some View {
        VStack(spacing: 6) {
            Text(audio.hasTrack ? audio.trackTitle : "NO DISC")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Deck.amber)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                Text(String(format: "%+.1f%%", audio.pitch))
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.green)
            }
            Button {
                showImporter = true
            } label: {
                Text("OPEN MP3")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color(white: 0.25)))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 110)
        .recessedWell(cornerRadius: 8)
    }

    private func pitchSection(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text("PITCH")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.black.opacity(0.55))
            Text("+8")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.5))
            PitchFaderView(value: audio.pitch) { audio.setPitch($0) }
                .frame(width: w * 0.085, height: h * 0.46)
            Text("−8")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.5))
        }
        .position(x: w * 0.90, y: h * 0.55)
    }
}

#Preview {
    ContentView()
}
