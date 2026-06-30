import Foundation

struct PlanExercise: Codable, Identifiable {
    let id: UUID
    var planId: UUID
    var exerciseId: UUID
    var sets: Int
    var reps: Int
    var restSeconds: Int
    var sortOrder: Int
    var notes: String
    var exercise: Exercise?

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case exerciseId = "exercise_id"
        case sets
        case reps
        case restSeconds = "rest_seconds"
        case sortOrder = "sort_order"
        case notes
        case exercise = "exercises"
    }

    init(id: UUID = UUID(), planId: UUID, exerciseId: UUID, sets: Int = 3, reps: Int = 10, restSeconds: Int = 90, sortOrder: Int = 0, notes: String = "", exercise: Exercise? = nil) {
        self.id = id
        self.planId = planId
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.sortOrder = sortOrder
        self.notes = notes
        self.exercise = exercise
    }
}
