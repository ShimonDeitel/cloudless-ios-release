import SwiftUI

/// Primary worry-entry screen. User types their worry, then swipes the cloud away.
struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var worryText = ""
    @State private var phase: Phase = .write
    @State private var swipeOffset: CGFloat = 0
    @State private var swipeOpacity: Double = 1

    private enum Phase { case write, swipe, done }

    var body: some View {
        ZStack {
            QMBackground()

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.body)
                        .foregroundStyle(Color.qmAccent)
                    Spacer()
                    Text(phase == .write ? "Today's Worry" : phase == .swipe ? "Let Go" : "Released")
                        .font(.headline)
                    Spacer()
                    // Balance cancel button
                    Color.clear.frame(width: 55, height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                Spacer()

                switch phase {
                case .write:
                    writePhase
                case .swipe:
                    swipePhase
                case .done:
                    donePhase
                }

                Spacer()
            }
        }
    }

    // MARK: - Write phase

    private var writePhase: some View {
        VStack(spacing: 28) {
            Image(systemName: "cloud")
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(Color.qmAccent)

            VStack(spacing: 10) {
                Text("What's worrying you today?")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Write it down — name it to tame it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.qmCard)
                if worryText.isEmpty {
                    Text("e.g. I might mess up the presentation...")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                }
                TextEditor(text: $worryText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(8)
            }
            .frame(height: 120)
            .padding(.horizontal, 24)

            Button("Put it on a cloud") {
                guard !worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Haptics.tap()
                appModel.saveWorry(text: worryText.trimmingCharacters(in: .whitespacesAndNewlines))
                withAnimation(.easeInOut(duration: 0.3)) { phase = .swipe }
            }
            .prominentButton()
            .disabled(worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Swipe phase

    private var swipePhase: some View {
        VStack(spacing: 32) {
            Text("Swipe to release")
                .font(.title3.weight(.semibold))
            Text("This worry no longer needs to\nlive in your head right now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Cloud card with gesture
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.qmCard)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)

                VStack(spacing: 14) {
                    Image(systemName: "cloud")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(Color.qmAccent)
                    if let worry = appModel.todaysWorry {
                        Text(worry.text)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("swipe up")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                .padding(24)
            }
            .padding(.horizontal, 32)
            .offset(y: swipeOffset)
            .opacity(swipeOpacity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow upward drag
                        swipeOffset = min(0, value.translation.height)
                        swipeOpacity = max(0, 1 + Double(swipeOffset) / 200)
                    }
                    .onEnded { value in
                        if value.translation.height < -80 {
                            // Dismiss
                            Haptics.success()
                            withAnimation(.easeOut(duration: 0.4)) {
                                swipeOffset = -500
                                swipeOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                if let worry = appModel.todaysWorry {
                                    appModel.dismissWorry(worry)
                                }
                                withAnimation { phase = .done }
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                swipeOffset = 0
                                swipeOpacity = 1
                            }
                        }
                    }
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Done phase

    private var donePhase: some View {
        VStack(spacing: 24) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(Color.qmAccent.opacity(0.25))
                .overlay(
                    Image(systemName: "wind")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.qmAccent)
                        .offset(x: 12, y: -8)
                )

            VStack(spacing: 10) {
                Text("Released")
                    .font(.title2.weight(.bold))
                Text("Your worry has drifted off.\nIt no longer has to weigh on you today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            MetricTile(value: "\(appModel.thisWeekReleaseCount)", label: "Released this week")
                .frame(maxWidth: 200)

            Button("Done") {
                Haptics.tap()
                dismiss()
            }
            .prominentButton()
        }
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
