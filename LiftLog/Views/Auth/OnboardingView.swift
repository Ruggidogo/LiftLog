import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.strengthtraining.traditional",
            color: Color(red: 0.13, green: 0.55, blue: 0.33),
            title: "Track Every Rep",
            subtitle: "Log your sets, reps and weight in real time — never lose a PR again."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            color: Color(red: 0.11, green: 0.47, blue: 0.29),
            title: "See Your Progress",
            subtitle: "Beautiful charts show exactly how your strength improves week after week."
        ),
        OnboardingPage(
            icon: "person.2.fill",
            color: Color(red: 0.09, green: 0.40, blue: 0.25),
            title: "Train With Your PT",
            subtitle: "Personal trainers can assign plans and monitor client performance remotely."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            color: Color(red: 0.13, green: 0.55, blue: 0.33),
            title: "Stay Consistent",
            subtitle: "Smart reminders keep you on schedule. Build habits that last."
        )
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo + brand
                VStack(spacing: 12) {
                    LiftLogLogoView(size: 80)
                    Text("LiftLog")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)

                // Page carousel
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color(red: 0.13, green: 0.75, blue: 0.43) : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // CTA buttons
                VStack(spacing: 12) {
                    Button {
                        showOnboarding = false
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(red: 0.13, green: 0.75, blue: 0.43))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        showOnboarding = false
                    } label: {
                        Text("I already have an account")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(Color(red: 0.13, green: 0.75, blue: 0.43))
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

// Programmatic logo — doppia L su sfondo verde arrotondato
struct LiftLogLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.70, blue: 0.42),
                            Color(red: 0.08, green: 0.45, blue: 0.27)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color(red: 0.13, green: 0.55, blue: 0.33).opacity(0.5), radius: size * 0.15, y: size * 0.08)

            // Doppia L: una normale, una capovolta
            VStack(spacing: size * 0.03) {
                LShape(size: size * 0.35)
                    .fill(.white)
                LShape(size: size * 0.35)
                    .fill(.white.opacity(0.75))
                    .rotationEffect(.degrees(180))
            }
        }
    }
}

struct LShape: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = size
        let h = size
        let t = size * 0.28  // thickness

        var path = Path()
        path.move(to: CGPoint(x: rect.midX - w/2, y: rect.midY - h/2))
        path.addLine(to: CGPoint(x: rect.midX - w/2 + t, y: rect.midY - h/2))
        path.addLine(to: CGPoint(x: rect.midX - w/2 + t, y: rect.midY + h/2 - t))
        path.addLine(to: CGPoint(x: rect.midX + w/2, y: rect.midY + h/2 - t))
        path.addLine(to: CGPoint(x: rect.midX + w/2, y: rect.midY + h/2))
        path.addLine(to: CGPoint(x: rect.midX - w/2, y: rect.midY + h/2))
        path.closeSubpath()
        return path
    }
}
