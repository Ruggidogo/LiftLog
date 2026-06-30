import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                LoginView()
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
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text("LiftLog")
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(localized: "tab.home"), systemImage: "house.fill")
                }

            CalendarView()
                .tabItem {
                    Label(String(localized: "tab.calendar"), systemImage: "calendar")
                }

            WorkoutPlanListView()
                .tabItem {
                    Label(String(localized: "tab.plans"), systemImage: "list.bullet.clipboard.fill")
                }

            StatsView()
                .tabItem {
                    Label(String(localized: "tab.stats"), systemImage: "chart.line.uptrend.xyaxis")
                }

            ProfileView()
                .tabItem {
                    Label(String(localized: "tab.profile"), systemImage: "person.fill")
                }
        }
    }
}
