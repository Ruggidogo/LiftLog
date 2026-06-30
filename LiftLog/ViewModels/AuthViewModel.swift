import Foundation
import SwiftUI

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case roleSelection
    case paywall
    case authenticated
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: AppUser?
    @Published var error: AppError?
    @Published var isLoading = false

    func checkSession() async {
        let hasSession = await AuthService.shared.currentSession()
        guard hasSession else {
            authState = .unauthenticated
            return
        }
        await loadUser()
    }

    private func loadUser() async {
        do {
            var user = try await AuthService.shared.fetchCurrentUser()
            try await AuthService.shared.checkAndUpdateSubscription(user: &user)
            currentUser = user
            if user.subscriptionStatus == .expired {
                authState = .paywall
            } else {
                authState = .authenticated
            }
        } catch {
            authState = .unauthenticated
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.signIn(email: email, password: password)
            await loadUser()
        } catch {
            self.error = .auth(error.localizedDescription)
        }
    }

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.signUp(email: email, password: password, fullName: fullName)
            guard let userId = await AuthService.shared.currentUserId() else { return }
            try await AuthService.shared.createUserProfile(userId: userId, email: email, fullName: fullName)
            var user = try await AuthService.shared.fetchCurrentUser()
            try await AuthService.shared.checkAndUpdateSubscription(user: &user)
            currentUser = user
            authState = .roleSelection
        } catch {
            self.error = .auth(error.localizedDescription)
        }
    }

    func selectRole(_ role: UserRole) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.updateRole(role)
            currentUser?.role = role
            authState = .authenticated
        } catch {
            self.error = .auth(error.localizedDescription)
        }
    }

    func signOut() async {
        do {
            try await AuthService.shared.signOut()
            currentUser = nil
            authState = .unauthenticated
        } catch {
            self.error = .auth(error.localizedDescription)
        }
    }

    func refreshUser() async {
        await loadUser()
    }
}
