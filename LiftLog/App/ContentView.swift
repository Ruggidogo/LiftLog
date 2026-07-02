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

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            WorkoutPlanListView()
                .tabItem { Label("Plans", systemImage: "list.bullet.clipboard.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.brand)
        .preferredColorScheme(.dark)
    }
}
