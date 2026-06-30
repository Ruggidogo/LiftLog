import Foundation

struct SessionSet: Codable, Identifiable {
    let id: UUID
    var sessionId: UUID
    var exerciseId: UUID
    var setNumber: Int
    var repsDone: Int
    var weightKg: Double
    var isBodyweight: Bool
    var completed: Bool
    var exercise: Exercise?

    var volume: Double {
        guard completed else { return 0 }
        return isBodyweight ? 0 : weightKg * Double(repsDone)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case repsDone = "reps_done"
        case weightKg = "weight_kg"
        case isBodyweight = "is_bodyweight"
        case completed
        case exercise = "exercises"
    }

    init(id: UUID = UUID(), sessionId: UUID, exerciseId: UUID, setNumber: Int, repsDone: Int = 0, weightKg: Double = 0, isBodyweight: Bool = false, completed: Bool = false, exercise: Exercise? = nil) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.repsDone = repsDone
        self.weightKg = weightKg
        self.isBodyweight = isBodyweight
        self.completed = completed
        self.exercise = exercise
    }
}

struct NotificationSettings: Codable {
    var userId: UUID
    var enabled: Bool
    var reminderTime: String
    var customMessage: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case enabled
        case reminderTime = "reminder_time"
        case customMessage = "custom_message"
    }
}
