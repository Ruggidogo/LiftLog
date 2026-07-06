import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                if hasSeenOnboarding {
                    LoginView()
                } else {
                    OnboardingView(showOnboarding: Binding(
                        get: { !hasSeenOnboarding },
                        set: { show in hasSeenOnboarding = !show }
                    ))
                }
            case .roleSelection:
                RoleSelectionView()
            case .paywall:
                PaywallView()
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                LiftLogLogoView(size: 90)
                    .scaleEffect(scale)
                    .opacity(opacity)
                Text("LiftLog")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    private let tabs: [(label: String, icon: String, selectedIcon: String)] = [
        ("Home",     "house",                    "house.fill"),
        ("Calendar", "calendar",                 "calendar.fill"),
        ("Plans",    "dumbbell",                 "dumbbell.fill"),
        ("Stats",    "chart.line.uptrend.xyaxis","chart.line.uptrend.xyaxis"),
        ("Profile",  "person.crop.circle",       "person.crop.circle.fill"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: CalendarView()
                case 2: WorkoutPlanListView()
                case 3: StatsView()
                default: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                let isSelected = selectedTab == index
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                // Glow behind selected icon
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.brand.opacity(0.15))
                                    .frame(width: 48, height: 34)
                            }
                            Image(systemName: isSelected ? tabs[index].selectedIcon : tabs[index].icon)
                                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(
                                    isSelected
                                    ? LinearGradient(colors: [.brand, Color(red: 0.0, green: 0.9, blue: 0.55)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.4)],
                                                     startPoint: .top, endPoint: .bottom)
                                )
                                .scaleEffect(isSelected ? 1.08 : 1.0)
                        }
                        Text(tabs[index].label)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .brand : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 20) // safe area
        .background(
            ZStack {
                // Frosted dark glass
                Color(red: 0.06, green: 0.08, blue: 0.07)
                Rectangle()
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
        }
    }
}
