import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // MARK: Pro section
                    Section("Cloudless Pro") {
                        if store.isPro {
                            HStack {
                                Text("Status")
                                Spacer()
                                Text("Active")
                                    .foregroundStyle(Color.qmCorrect)
                                    .font(.subheadline.weight(.medium))
                            }
                            Link("Manage Subscription",
                                 destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                .foregroundStyle(Color.qmAccent)
                        } else {
                            Button("Unlock Cloudless Pro — \(store.displayPrice)/mo") {
                                showPaywall = true
                            }
                            .foregroundStyle(Color.qmAccent)

                            Button("Restore Purchases") {
                                Task { await store.restore() }
                            }
                            .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // MARK: Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme.rawValue)
                            }
                        }
                    }

                    // MARK: Notifications (Pro)
                    Section("Reminders") {
                        if store.isPro {
                            ReminderToggleRow()
                        } else {
                            HStack {
                                Text("Evening Reminder")
                                Spacer()
                                Text("Pro")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.qmAccent, in: Capsule())
                            }
                        }
                    }

                    // MARK: Links
                    Section("Legal") {
                        Link("Privacy Policy",
                             destination: URL(string: "https://shimondeitel.github.io/cloudless-site/privacy.html")!)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // MARK: Data
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete All Data")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .confirmationDialog("Delete all worries and data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                appModel.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}

// MARK: - Reminder toggle (Pro only)

private struct ReminderToggleRow: View {
    @State private var enabled = false
    @State private var hour = 20
    @State private var minute = 0

    var body: some View {
        Toggle("Evening Reminder", isOn: $enabled)
            .onChange(of: enabled) { _, newVal in
                if newVal {
                    Task {
                        let granted = await Reminders.requestAuthorization()
                        if granted {
                            Reminders.schedule(hour: hour, minute: minute)
                        } else {
                            enabled = false
                        }
                    }
                } else {
                    Reminders.cancel()
                }
            }
        if enabled {
            DatePicker("Time", selection: Binding(
                get: {
                    var c = DateComponents(); c.hour = hour; c.minute = minute
                    return Calendar.current.date(from: c) ?? Date()
                },
                set: { d in
                    let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                    hour = c.hour ?? 20; minute = c.minute ?? 0
                    Reminders.schedule(hour: hour, minute: minute)
                }
            ), displayedComponents: .hourAndMinute)
        }
    }
}
