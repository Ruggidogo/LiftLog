import SwiftUI
import SwiftData

@main
struct LiftLogApp: SwiftUI.App {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("appTheme") private var appTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(colorScheme(for: appTheme))
                .task {
                    await authViewModel.checkSession()
                    NotificationService.shared.requestAuthorization()
                }
        }
        .modelContainer(for: [
            CachedSession.self,
            CachedExercise.self
        ])
    }

    private func colorScheme(for theme: String) -> ColorScheme? {
        switch theme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
}
