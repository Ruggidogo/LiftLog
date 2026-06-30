import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [String]
    var equipment: String
    var isCustom: Bool
    var isGlobal: Bool
    var createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case muscleGroups = "muscle_groups"
        case equipment
        case isCustom = "is_custom"
        case isGlobal = "is_global"
        case createdBy = "created_by"
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case bodyweight
    case weights
    case powerlifting
    case crossfit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bodyweight: return String(localized: "category.bodyweight")
        case .weights: return String(localized: "category.weights")
        case .powerlifting: return String(localized: "category.powerlifting")
        case .crossfit: return String(localized: "category.crossfit")
        }
    }

    var icon: String {
        switch self {
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .weights: return "dumbbell.fill"
        case .powerlifting: return "trophy.fill"
        case .crossfit: return "bolt.fill"
        }
    }
}
