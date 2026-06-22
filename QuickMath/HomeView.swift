import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showGrid = false

    var body: some View {
        ZStack {
            QMBackground()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 6) {
                            Text("Cloudless")
                                .font(.largeTitle.weight(.bold))
                            Text("Name today's worry, let go")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 12)

                        // Today's worry status
                        todayCard

                        // Week stats
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.thisWeekReleaseCount)", label: "Released this week")
                            MetricTile(value: "\(appModel.totalResolved)", label: "Total released")
                        }

                        // Pro card
                        proCard

                        // Pending reviews (free: teaser)
                        if !appModel.pendingReview.isEmpty {
                            reviewTeaser
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showInsights) { InsightsView() }
        .sheet(isPresented: $showGrid) { GridView() }
        .onAppear { handleForceScreen() }
    }

    // MARK: - Sub-views

    private var todayCard: some View {
        VStack(spacing: 16) {
            if let worry = appModel.todaysWorry {
                // Already written today
                VStack(spacing: 10) {
                    Image(systemName: "cloud")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(Color.qmAccent)
                    Text(worry.text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    if worry.resolved == true {
                        Label("Released", systemImage: "wind")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.qmCorrect)
                    } else {
                        Button("Swipe it away") {
                            Haptics.success()
                            appModel.dismissWorry(worry)
                        }
                        .prominentButton()
                    }
                }
            } else {
                // No worry yet
                VStack(spacing: 12) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(Color.qmAccent.opacity(0.3))
                    Text("What's weighing on you today?")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("Name a worry") {
                        Haptics.tap()
                        showGrid = true
                    }
                    .prominentButton()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .qmCard()
    }

    private var proCard: some View {
        Button {
            Haptics.tap()
            if store.isPro { showInsights = true } else { showPaywall = true }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(Color.qmAccent)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(store.isPro ? "Worry Insights" : "Unlock Insights")
                            .font(.headline)
                        if store.isPro {
                            Text("PRO")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.qmAccent, in: Capsule())
                        }
                    }
                    Text(store.isPro ? "See trends, follow-ups & monthly patterns" : "Reviews, archive, patterns — \(store.displayPrice)/mo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .qmCard()
    }

    private var reviewTeaser: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(appModel.pendingReview.count) worr\(appModel.pendingReview.count == 1 ? "y" : "ies") ready for review")
                .font(.subheadline.weight(.medium))
            Text("Did they come true? Unlock Pro to find out.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Unlock Reviews") {
                Haptics.tap()
                showPaywall = true
            }
            .softButton()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .qmCard()
    }

    // MARK: - Force screen

    private func handleForceScreen() {
        guard let fs = forceScreen else { return }
        switch fs {
        case "grid": showGrid = true
        case "insights": showInsights = true
        case "paywall": showPaywall = true
        case "settings": showSettings = true
        default: break
        }
    }
}
