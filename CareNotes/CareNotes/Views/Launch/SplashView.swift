//
//  SplashView.swift
//  CareNotes
//

// Brand intro shown straight after the system launch screen: the
// logo stays exactly where the launch screen drew it, then the app
// name and tagline fade in, and the app fades in after about a second.

// Business Rule: The intro never blocks the user for long. It lasts
// ~1.2s, can be skipped with a tap, and has no motion when Reduce
// Motion is on.

import SwiftUI

/// Shows `SplashView` on top of the app's first screen, then removes it.
struct SplashContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            content()
            if isShowingSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.55)) { isShowingSplash = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

struct SplashView: View {
    /// Matches the launch screen image (200pt, icon + soft shadow) so the hand-off doesn't jump.
    static let logoSize: CGFloat = 200
    static let duration: Duration = .milliseconds(3000)

    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingTitle = false
    @State private var hasFinished = false

    var body: some View {
        ZStack {
            // White in Light Mode, black in Dark Mode — same as the launch screen.
            Color("LaunchBackground").ignoresSafeArea()

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: Self.logoSize, height: Self.logoSize)
                .accessibilityHidden(true)
                // Title hangs below the logo without moving the logo off-centre.
                .overlay(alignment: .bottom) {
                    title.alignmentGuide(.bottom) { $0[.top] }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .task {
            if reduceMotion {
                isShowingTitle = true
            } else {
                withAnimation(.easeOut(duration: 0.6).delay(0.30)) { isShowingTitle = true }
            }
            try? await Task.sleep(for: Self.duration)
            finish()
        }
    }

    private var title: some View {
        VStack(spacing: 6) {
            Text("CareNotes")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Text("Caring made simple.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        // Wraps onto two lines at large text sizes instead of running off-screen.
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .opacity(isShowingTitle ? 1 : 0)
        .offset(y: isShowingTitle || reduceMotion ? 0 : 8)
        .accessibilityElement(children: .combine)
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinished()
    }
}

#Preview {
    SplashView {}
}
