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
            struct Payload: Encodable {
                let user_id: String
                let enabled: Bool
                let reminder_time: String
                let custom_message: String
            }
            let payload = Payload(
                user_id: settings.userId.uuidString,
                enabled: settings.enabled,
                reminder_time: settings.reminderTime,
                custom_message: settings.customMessage
            )
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
        struct Fields: Encodable {
            let full_name: String
            let theme: String
            let language: String
        }
        let fields = Fields(
            full_name: user.fullName,
            theme: user.theme.rawValue,
            language: user.language.rawValue
        )
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
