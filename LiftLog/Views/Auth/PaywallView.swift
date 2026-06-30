import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isCheckingPayment = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                Text(String(localized: "paywall.title"))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(String(localized: "paywall.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 8) {
                PaywallFeatureRow(icon: "chart.line.uptrend.xyaxis", text: String(localized: "paywall.feature.stats"))
                PaywallFeatureRow(icon: "calendar.badge.checkmark", text: String(localized: "paywall.feature.calendar"))
                PaywallFeatureRow(icon: "list.bullet.clipboard.fill", text: String(localized: "paywall.feature.plans"))
                PaywallFeatureRow(icon: "dumbbell.fill", text: String(localized: "paywall.feature.sessions"))
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Text(Constants.Stripe.monthlyPrice + " / " + String(localized: "paywall.month"))
                    .font(.title2.bold())

                Button {
                    if let userId = authViewModel.currentUser?.id {
                        StripeService.shared.openCheckout(userId: userId)
                        isCheckingPayment = true
                    }
                } label: {
                    Text(String(localized: "paywall.cta"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    Task {
                        isCheckingPayment = true
                        await authViewModel.refreshUser()
                        isCheckingPayment = false
                    }
                } label: {
                    Text(String(localized: "paywall.restore"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }

                Button(role: .destructive) {
                    Task { await authViewModel.signOut() }
                } label: {
                    Text(String(localized: "button.signout"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .overlay {
            if isCheckingPayment {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.caption.bold())
        }
    }
}
