import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, text: String)] = [
        ("magnifyingglass", "Worry follow-up reviews showing how few came true"),
        ("folder", "Full searchable worry archive and trends"),
        ("bell.badge", "Evening reminder and monthly anxiety-pattern recap")
    ]

    var body: some View {
        ZStack {
            QMBackground()
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "cloud")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundStyle(Color.qmAccent)
                            .padding(.top, 40)

                        Text("Cloudless Pro")
                            .font(.largeTitle.weight(.bold))

                        Text("$0.99 / month. Auto-renews until you cancel.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(benefits, id: \.text) { benefit in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: benefit.icon)
                                    .font(.body)
                                    .foregroundStyle(Color.qmAccent)
                                    .frame(width: 24)
                                Text(benefit.text)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)

                    // Purchase button
                    Button {
                        Task {
                            Haptics.tap()
                            _ = await store.purchase()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if store.purchaseInFlight {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Text("Unlock for \(store.displayPrice)/month")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .prominentButton()
                    .disabled(store.purchaseInFlight)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                    // Restore
                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.qmAccent)
                    .padding(.bottom, 28)

                    // Disclosure
                    VStack(spacing: 10) {
                        Text("Subscription automatically renews at \(store.displayPrice)/month unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple Account settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/cloudless-site/privacy.html")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.qmAccent)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: store.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }
}
