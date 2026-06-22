import SwiftUI

/// Pro-only view: full searchable archive, trends, and worry follow-up reviews.
struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedTab: InsightTab = .archive

    private enum InsightTab: String, CaseIterable {
        case archive = "Archive"
        case reviews = "Reviews"
        case trends = "Trends"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(InsightTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    switch selectedTab {
                    case .archive:
                        archiveTab
                    case .reviews:
                        reviewsTab
                    case .trends:
                        trendsTab
                    }
                }
            }
            .navigationTitle("Worry Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    // MARK: - Archive Tab

    private var archiveTab: some View {
        let filtered = appModel.worries.filter {
            searchText.isEmpty || $0.text.localizedCaseInsensitiveContains(searchText)
        }
        return List {
            ForEach(filtered, id: \.id) { worry in
                ArchiveRow(worry: worry)
            }
        }
        .searchable(text: $searchText, prompt: "Search worries")
        .listStyle(.plain)
        .overlay {
            if appModel.worries.isEmpty {
                ContentUnavailableView(
                    "No worries yet",
                    systemImage: "cloud",
                    description: Text("Start writing a daily worry from the home screen.")
                )
            }
        }
    }

    // MARK: - Reviews Tab

    private var reviewsTab: some View {
        let pending = appModel.pendingReview
        return List {
            if !pending.isEmpty {
                Section("Pending Review") {
                    ForEach(pending, id: \.id) { worry in
                        ReviewRow(worry: worry)
                    }
                }
            }

            let reviewed = appModel.worries.filter { $0.resolved == true && $0.cameTrue != nil }
            if !reviewed.isEmpty {
                Section("Completed Reviews") {
                    ForEach(reviewed, id: \.id) { worry in
                        ArchiveRow(worry: worry)
                    }
                }
            }

            if pending.isEmpty && reviewed.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Nothing to review yet",
                        systemImage: "checkmark.circle",
                        description: Text("Worries older than 7 days will appear here for follow-up.")
                    )
                    .padding(.vertical, 32)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Trends Tab

    private var trendsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary stats
                HStack(spacing: 12) {
                    MetricTile(value: "\(appModel.worries.count)", label: "Total worries")
                    MetricTile(value: "\(appModel.totalResolved)", label: "Released")
                }
                HStack(spacing: 12) {
                    MetricTile(value: "\(appModel.totalNotTrue)", label: "Never came true")
                    MetricTile(value: "\(appModel.totalCameTrue)", label: "Came true")
                }

                // Reassurance note
                if appModel.totalNotTrue > 0 {
                    VStack(spacing: 8) {
                        let pct = appModel.totalResolved > 0
                            ? Int(Double(appModel.totalNotTrue) / Double(appModel.totalResolved) * 100)
                            : 0
                        Text("\(pct)% of your resolved worries never came true.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text("Most of what we fear never happens. Keep releasing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .qmCard()
                }

                // Monthly pattern
                let monthlyGroups = monthlyBreakdown()
                if !monthlyGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Pattern")
                            .font(.headline)
                        ForEach(monthlyGroups, id: \.month) { group in
                            HStack {
                                Text(group.month)
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .leading)
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.qmAccent.opacity(0.7))
                                        .frame(width: max(4, CGFloat(group.count) / CGFloat(maxMonthCount()) * geo.size.width))
                                        .frame(height: 20)
                                }
                                Text("\(group.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24, alignment: .trailing)
                            }
                            .frame(height: 20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .qmCard()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Helpers

    private struct MonthGroup { let month: String; let count: Int }

    private func monthlyBreakdown() -> [MonthGroup] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        var dict: [String: Int] = [:]
        for w in appModel.worries {
            let key = fmt.string(from: w.date)
            dict[key, default: 0] += 1
        }
        return dict.map { MonthGroup(month: $0.key, count: $0.value) }
            .sorted { $0.month > $1.month }
            .prefix(6)
            .map { $0 }
    }

    private func maxMonthCount() -> Int {
        monthlyBreakdown().map { $0.count }.max() ?? 1
    }
}

// MARK: - Supporting Row Views

private struct ArchiveRow: View {
    let worry: WorryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(worry.text)
                .font(.body)
                .lineLimit(2)
            HStack(spacing: 8) {
                Text(worry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if worry.resolved == true {
                    if let ct = worry.cameTrue {
                        Label(ct ? "Came true" : "Never happened", systemImage: ct ? "exclamationmark.circle" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(ct ? Color.qmWrong : Color.qmCorrect)
                    } else {
                        Label("Released", systemImage: "wind")
                            .font(.caption2)
                            .foregroundStyle(Color.qmCorrect)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ReviewRow: View {
    @EnvironmentObject var appModel: AppModel
    let worry: WorryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(worry.text)
                .font(.body)
                .lineLimit(3)
            Text("From \(worry.date.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    Haptics.success()
                    appModel.markWorry(worry, cameTrue: false)
                } label: {
                    Label("Never happened", systemImage: "checkmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.qmCorrect)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.warning()
                    appModel.markWorry(worry, cameTrue: true)
                } label: {
                    Label("It came true", systemImage: "exclamationmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.qmWrong)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
