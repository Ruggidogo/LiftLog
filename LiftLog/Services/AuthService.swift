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
        let metadata: [String: AnyJSON] = ["full_name": .string(fullName)]
        try await client.auth.signUp(email: email, password: password, data: metadata)
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
        let trialEnd = Calendar.current.date(byAdding: .day, value: Constants.Trial.durationDays, to: Date())!
        let profile: [String: AnyJSON] = [
            "id": .string(userId.uuidString),
            "email": .string(email),
            "full_name": .string(fullName),
            "role": .string("athlete"),
            "theme": .string("system"),
            "language": .string("en"),
            "subscription_status": .string("trial"),
            "trial_end_date": .string(ISO8601DateFormatter().string(from: trialEnd)),
            "created_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        try await client
            .from(Constants.Tables.users)
            .insert(profile)
            .execute()
    }

    func updateRole(_ role: UserRole) async throws {
        guard let userId = await currentUserId() else { return }
        try await client
            .from(Constants.Tables.users)
            .update(["role": role.rawValue])
            .eq("id", value: userId)
            .execute()
    }

    func updateUser(_ fields: [String: AnyJSON]) async throws {
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
        try await updateUser(["subscription_status": "expired"])
        user.subscriptionStatus = .expired
    }
}
