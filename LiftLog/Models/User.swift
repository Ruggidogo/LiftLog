import Foundation

struct AppUser: Codable, Identifiable {
    let id: UUID
    var email: String
    var fullName: String
    var role: UserRole
    var theme: AppTheme
    var language: AppLanguage
    var subscriptionStatus: SubscriptionStatus
    var trialEndDate: Date?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case theme
        case language
        case subscriptionStatus = "subscription_status"
        case trialEndDate = "trial_end_date"
        case createdAt = "created_at"
    }
}

enum UserRole: String, Codable, CaseIterable {
    case athlete
    case pt
    case admin

    var displayName: String {
        switch self {
        case .athlete: return String(localized: "role.athlete")
        case .pt: return String(localized: "role.pt")
        case .admin: return String(localized: "role.admin")
        }
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case dark
    case light
    case system

    var displayName: String {
        switch self {
        case .dark: return String(localized: "theme.dark")
        case .light: return String(localized: "theme.light")
        case .system: return String(localized: "theme.system")
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable {
    case it
    case en

    var displayName: String {
        switch self {
        case .it: return "Italiano"
        case .en: return "English"
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case trial
    case active
    case expired
}

struct PTClient: Codable, Identifiable {
    let id: UUID
    let ptId: UUID
    let clientId: UUID
    var clientUser: AppUser?

    enum CodingKeys: String, CodingKey {
        case id
        case ptId = "pt_id"
        case clientId = "client_id"
    }
}
