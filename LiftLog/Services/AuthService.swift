import Foundation
import Supabase

final class AuthService {
    static let shared = AuthService()
    private let client = SupabaseService.shared.client

    private init() {}

    func currentSession() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }

    func currentUserId() async -> UUID? {
        try? await client.auth.session.user.id
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, fullName: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func fetchCurrentUser() async throws -> AppUser {
        guard let userId = await currentUserId() else {
            throw AppError.auth(String(localized: "error.not_authenticated"))
        }
        let response: AppUser = try await client
            .from(Constants.Tables.users)
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return response
    }

    func createUserProfile(userId: UUID, email: String, fullName: String) async throws {
        struct Profile: Encodable {
            let id: String
            let email: String
            let full_name: String
            let role: String
            let theme: String
            let language: String
            let subscription_status: String
            let trial_end_date: String
            let created_at: String
        }
        let trialEnd = Calendar.current.date(byAdding: .day, value: Constants.Trial.durationDays, to: Date())!
        let fmt = ISO8601DateFormatter()
        let profile = Profile(
            id: userId.uuidString,
            email: email,
            full_name: fullName,
            role: "athlete",
            theme: "system",
            language: "en",
            subscription_status: "trial",
            trial_end_date: fmt.string(from: trialEnd),
            created_at: fmt.string(from: Date())
        )
        try await client
            .from(Constants.Tables.users)
            .insert(profile)
            .execute()
    }

    func updateRole(_ role: UserRole) async throws {
        guard let userId = await currentUserId() else { return }
        struct RoleUpdate: Encodable { let role: String }
        try await client
            .from(Constants.Tables.users)
            .update(RoleUpdate(role: role.rawValue))
            .eq("id", value: userId)
            .execute()
    }

    func updateUser<T: Encodable>(_ fields: T) async throws {
        guard let userId = await currentUserId() else { return }
        try await client
            .from(Constants.Tables.users)
            .update(fields)
            .eq("id", value: userId)
            .execute()
    }

    func checkAndUpdateSubscription(user: inout AppUser) async throws {
        guard user.subscriptionStatus == .trial,
              let trialEnd = user.trialEndDate,
              trialEnd < Date() else { return }
        struct StatusUpdate: Encodable { let subscription_status: String }
        try await updateUser(StatusUpdate(subscription_status: "expired"))
        user.subscriptionStatus = .expired
    }
}
