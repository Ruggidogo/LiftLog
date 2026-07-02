import Foundation
import Supabase

final class ExerciseService {
    static let shared = ExerciseService()
    private let client = SupabaseService.shared.client

    private init() {}

    func fetchExercises() async throws -> [Exercise] {
        let response: [Exercise] = try await client
            .from(Constants.Tables.exercises)
            .select()
            .order("name")
            .execute()
            .value
        return response
    }

    func fetchExercises(forUser userId: UUID) async throws -> [Exercise] {
        let response: [Exercise] = try await client
            .from(Constants.Tables.exercises)
            .select()
            .or("is_global.eq.true,created_by.eq.\(userId.uuidString)")
            .order("name")
            .execute()
            .value
        return response
    }

    func createCustomExercise(_ exercise: Exercise) async throws -> Exercise {
        struct ExerciseInsert: Encodable {
            let id: String
            let name: String
            let category: String
            let muscle_groups: [String]
            let equipment: String
            let is_custom: Bool
            let is_global: Bool
            let created_by: String?
        }
        let payload = ExerciseInsert(
            id: exercise.id.uuidString,
            name: exercise.name,
            category: exercise.category.rawValue,
            muscle_groups: exercise.muscleGroups,
            equipment: exercise.equipment,
            is_custom: true,
            is_global: false,
            created_by: exercise.createdBy?.uuidString
        )
        let response: Exercise = try await client
            .from(Constants.Tables.exercises)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func deleteExercise(id: UUID) async throws {
        try await client
            .from(Constants.Tables.exercises)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    static let seedExercises: [Exercise] = [
        // BODYWEIGHT
        Exercise(id: UUID(), name: "Push-up", category: .bodyweight, muscleGroups: ["Chest","Triceps","Shoulders"], equipment: "None", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Pull-up", category: .bodyweight, muscleGroups: ["Back","Biceps"], equipment: "Pull-up bar", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Squat", category: .bodyweight, muscleGroups: ["Quads","Glutes","Hamstrings"], equipment: "None", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Dip", category: .bodyweight, muscleGroups: ["Chest","Triceps","Shoulders"], equipment: "Dip bars", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Plank", category: .bodyweight, muscleGroups: ["Core","Shoulders"], equipment: "None", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Burpee", category: .bodyweight, muscleGroups: ["Full Body"], equipment: "None", isCustom: false, isGlobal: true, createdBy: nil),
        // WEIGHTS
        Exercise(id: UUID(), name: "Bench Press", category: .weights, muscleGroups: ["Chest","Triceps","Shoulders"], equipment: "Barbell, Bench", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Dumbbell Curl", category: .weights, muscleGroups: ["Biceps"], equipment: "Dumbbells", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Romanian Deadlift", category: .weights, muscleGroups: ["Hamstrings","Glutes","Lower Back"], equipment: "Barbell or Dumbbells", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Overhead Press", category: .weights, muscleGroups: ["Shoulders","Triceps"], equipment: "Barbell", isCustom: false, isGlobal: true, createdBy: nil),
        // POWERLIFTING
        Exercise(id: UUID(), name: "Back Squat", category: .powerlifting, muscleGroups: ["Quads","Glutes","Core","Back"], equipment: "Barbell, Squat rack", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Conventional Deadlift", category: .powerlifting, muscleGroups: ["Hamstrings","Glutes","Back","Traps"], equipment: "Barbell", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Paused Bench Press", category: .powerlifting, muscleGroups: ["Chest","Triceps","Shoulders"], equipment: "Barbell, Bench", isCustom: false, isGlobal: true, createdBy: nil),
        // CROSSFIT
        Exercise(id: UUID(), name: "Thruster", category: .crossfit, muscleGroups: ["Quads","Shoulders","Triceps","Core"], equipment: "Barbell or Dumbbells", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Kettlebell Swing", category: .crossfit, muscleGroups: ["Glutes","Hamstrings","Core","Shoulders"], equipment: "Kettlebell", isCustom: false, isGlobal: true, createdBy: nil),
        Exercise(id: UUID(), name: "Box Jump", category: .crossfit, muscleGroups: ["Quads","Glutes","Calves"], equipment: "Box", isCustom: false, isGlobal: true, createdBy: nil),
    ]
}
