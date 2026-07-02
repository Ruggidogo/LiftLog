import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isCheckingPayment = false

    private let features: [(icon: String, text: String)] = [
        ("chart.line.uptrend.xyaxis", "Advanced progress charts & analytics"),
        ("calendar.badge.checkmark", "Full training calendar & scheduling"),
        ("list.bullet.clipboard.fill", "Unlimited workout plans"),
        ("figure.strengthtraining.traditional", "Unlimited session tracking"),
        ("person.2.fill", "PT client management"),
        ("bell.badge.fill", "Smart training reminders")
    ]

    var body: some View {
        ZStack {
            Color.brandDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon + title
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.brand.opacity(0.15))
                            .frame(width: 100, height: 100)
                        LiftLogLogoView(size: 64)
                    }

                    VStack(spacing: 8) {
                        Text("Unlock LiftLog")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Everything you need to train smarter")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 36)

                // Features
                VStack(spacing: 0) {
                    ForEach(features, id: \.text) { feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.brand)
                                .frame(width: 28)
                            Text(feature.text)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.brand)
                        }
                        .padding(.vertical, 12)
                        if feature.text != features.last?.text {
                            Divider().background(Color.divider)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.divider, lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                Spacer()

                // CTA
                VStack(spacing: 14) {
                    VStack(spacing: 4) {
                        Text(Constants.Stripe.monthlyPrice)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("per month · cancel anytime")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    BrandButton(title: "Start Free Trial", isLoading: isCheckingPayment) {
                        if let userId = authViewModel.currentUser?.id {
                            StripeService.shared.openCheckout(userId: userId)
                            isCheckingPayment = true
                        }
                    }

                    Button {
                        Task {
                            isCheckingPayment = true
                            await authViewModel.refreshUser()
                            isCheckingPayment = false
                        }
                    } label: {
                        Text("Restore Purchase")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }

                    Button(role: .destructive) {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Text("Sign Out")
                            .font(.caption)
                            .foregroundColor(.textSecondary.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
    }
}
