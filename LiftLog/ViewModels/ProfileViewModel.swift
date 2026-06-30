import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var notificationSettings: NotificationSettings?
    @Published var clients: [AppUser] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: AppError?
    @Published var showAddClient = false

    private let client = SupabaseService.shared.client

    func loadNotificationSettings(for userId: UUID) async {
        do {
            let result: [NotificationSettings] = try await client
                .from(Constants.Tables.notificationSettings)
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            if let settings = result.first {
                notificationSettings = settings
            } else {
                notificationSettings = NotificationSettings(userId: userId, enabled: true, reminderTime: "08:00", customMessage: "")
            }
        } catch {
            notificationSettings = NotificationSettings(userId: userId, enabled: true, reminderTime: "08:00", customMessage: "")
        }
    }

    func saveNotificationSettings(_ settings: NotificationSettings) async {
        isSaving = true
        defer { isSaving = false }
        do {
            let payload: [String: AnyJSON] = [
                "user_id": .string(settings.userId.uuidString),
                "enabled": .bool(settings.enabled),
                "reminder_time": .string(settings.reminderTime),
                "custom_message": .string(settings.customMessage)
            ]
            try await client
                .from(Constants.Tables.notificationSettings)
                .upsert(payload)
                .execute()
            notificationSettings = settings
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func updateProfile(user: AppUser) async throws {
        isSaving = true
        defer { isSaving = false }
        let fields: [String: AnyJSON] = [
            "full_name": .string(user.fullName),
            "theme": .string(user.theme.rawValue),
            "language": .string(user.language.rawValue)
        ]
        try await AuthService.shared.updateUser(fields)
    }

    func loadClients(for ptId: UUID) async {
        do {
            clients = try await WorkoutService.shared.fetchClients(for: ptId)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func addClient(ptId: UUID, email: String) async throws {
        try await WorkoutService.shared.addClient(ptId: ptId, clientEmail: email)
        await loadClients(for: ptId)
    }

    func removeClient(ptId: UUID, clientId: UUID) async {
        do {
            try await WorkoutService.shared.removeClient(ptId: ptId, clientId: clientId)
            clients.removeAll { $0.id == clientId }
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }
}
