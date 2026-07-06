import Foundation

struct WorkoutPlan: Codable, Identifiable {
    let id: UUID
    var name: String
    var goal: WorkoutGoal
    var createdBy: UUID
    var assignedTo: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case goal
        case createdBy = "created_by"
        case assignedTo = "assigned_to"
        case createdAt = "created_at"
    }
}

enum WorkoutGoal: String, Codable, CaseIterable, Identifiable {
    case strength
    case hypertrophy
    case endurance
    case weightLoss = "weight_loss"
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Hypertrophy"
        case .endurance: return "Endurance"
        case .weightLoss: return "Weight Loss"
        case .mixed: return "Mixed"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "bolt.fill"
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .endurance: return "heart.fill"
        case .weightLoss: return "flame.fill"
        case .mixed: return "star.fill"
        }
    }
}
