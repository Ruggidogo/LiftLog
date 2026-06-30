import Foundation
import SwiftData

@Model
final class CachedSession {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var scheduledDate: Date
    var startedAt: Date?
    var endedAt: Date?
    var notes: String
    var planId: UUID?

    init(from session: Session) {
        self.id = session.id
        self.userId = session.userId
        self.scheduledDate = session.scheduledDate
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.notes = session.notes
        self.planId = session.planId
    }

    func toSession() -> Session {
        Session(id: id, userId: userId, planId: planId, scheduledDate: scheduledDate, startedAt: startedAt, endedAt: endedAt, notes: notes)
    }
}

@Model
final class CachedExercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var muscleGroups: [String]
    var equipment: String
    var isCustom: Bool
    var isGlobal: Bool

    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.categoryRaw = exercise.category.rawValue
        self.muscleGroups = exercise.muscleGroups
        self.equipment = exercise.equipment
        self.isCustom = exercise.isCustom
        self.isGlobal = exercise.isGlobal
    }

    func toExercise() -> Exercise {
        Exercise(
            id: id,
            name: name,
            category: ExerciseCategory(rawValue: categoryRaw) ?? .weights,
            muscleGroups: muscleGroups,
            equipment: equipment,
            isCustom: isCustom,
            isGlobal: isGlobal,
            createdBy: nil
        )
    }
}
