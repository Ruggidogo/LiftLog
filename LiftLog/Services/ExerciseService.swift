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
        let payload: [String: AnyJSON] = [
            "id": .string(exercise.id.uuidString),
            "name": .string(exercise.name),
            "category": .string(exercise.category.rawValue),
            "muscle_groups": .array(exercise.muscleGroups.map { .string($0) }),
            "equipment": .string(exercise.equipment),
            "is_custom": .bool(true),
            "is_global": .bool(false),
            "created_by": .string(exercise.createdBy?.uuidString ?? "")
        ]
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
        Exercise(id: UUID(), name: "Push-up", category: .bodyweight, muscleGroups: ["Chest", "Triceps", "Shoulders"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Pull-up", category: .bodyweight, muscleGroups: ["Back", "Biceps"], equipment: "Pull-up bar", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Squat", category: .bodyweight, muscleGroups: ["Quads", "Glutes", "Hamstrings"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Dip", category: .bodyweight, muscleGroups: ["Chest", "Triceps", "Shoulders"], equipment: "Dip bars", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Lunge", category: .bodyweight, muscleGroups: ["Quads", "Glutes", "Hamstrings"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Plank", category: .bodyweight, muscleGroups: ["Core", "Shoulders"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Burpee", category: .bodyweight, muscleGroups: ["Full Body"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Mountain Climber", category: .bodyweight, muscleGroups: ["Core", "Shoulders", "Quads"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Jump Squat", category: .bodyweight, muscleGroups: ["Quads", "Glutes", "Calves"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Pike Push-up", category: .bodyweight, muscleGroups: ["Shoulders", "Triceps"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Chin-up", category: .bodyweight, muscleGroups: ["Biceps", "Back"], equipment: "Pull-up bar", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Tricep Dip (bench)", category: .bodyweight, muscleGroups: ["Triceps", "Chest"], equipment: "Bench", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Glute Bridge", category: .bodyweight, muscleGroups: ["Glutes", "Hamstrings", "Core"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Hollow Body Hold", category: .bodyweight, muscleGroups: ["Core"], equipment: "None", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Pistol Squat", category: .bodyweight, muscleGroups: ["Quads", "Glutes", "Balance"], equipment: "None", isCustom: false, isGlobal: true),

        // WEIGHTS
        Exercise(id: UUID(), name: "Bench Press", category: .weights, muscleGroups: ["Chest", "Triceps", "Shoulders"], equipment: "Barbell, Bench", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Incline Dumbbell Press", category: .weights, muscleGroups: ["Upper Chest", "Shoulders", "Triceps"], equipment: "Dumbbells, Incline Bench", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Dumbbell Shoulder Press", category: .weights, muscleGroups: ["Shoulders", "Triceps"], equipment: "Dumbbells", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Lateral Raise", category: .weights, muscleGroups: ["Lateral Deltoid"], equipment: "Dumbbells", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Barbell Row", category: .weights, muscleGroups: ["Back", "Biceps", "Rear Deltoid"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Seated Cable Row", category: .weights, muscleGroups: ["Back", "Biceps"], equipment: "Cable machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Lat Pulldown", category: .weights, muscleGroups: ["Back", "Biceps"], equipment: "Cable machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Dumbbell Curl", category: .weights, muscleGroups: ["Biceps"], equipment: "Dumbbells", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Skull Crusher", category: .weights, muscleGroups: ["Triceps"], equipment: "EZ-bar, Bench", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Goblet Squat", category: .weights, muscleGroups: ["Quads", "Glutes", "Core"], equipment: "Kettlebell or Dumbbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Romanian Deadlift", category: .weights, muscleGroups: ["Hamstrings", "Glutes", "Lower Back"], equipment: "Barbell or Dumbbells", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Leg Press", category: .weights, muscleGroups: ["Quads", "Glutes", "Hamstrings"], equipment: "Leg press machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Leg Curl", category: .weights, muscleGroups: ["Hamstrings"], equipment: "Leg curl machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Leg Extension", category: .weights, muscleGroups: ["Quads"], equipment: "Leg extension machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Calf Raise", category: .weights, muscleGroups: ["Calves"], equipment: "Machine or Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Face Pull", category: .weights, muscleGroups: ["Rear Deltoid", "Rotator Cuff"], equipment: "Cable machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Cable Fly", category: .weights, muscleGroups: ["Chest"], equipment: "Cable machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Hammer Curl", category: .weights, muscleGroups: ["Biceps", "Brachialis"], equipment: "Dumbbells", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Tricep Pushdown", category: .weights, muscleGroups: ["Triceps"], equipment: "Cable machine", isCustom: false, isGlobal: true),

        // POWERLIFTING
        Exercise(id: UUID(), name: "Back Squat", category: .powerlifting, muscleGroups: ["Quads", "Glutes", "Core", "Back"], equipment: "Barbell, Squat rack", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Conventional Deadlift", category: .powerlifting, muscleGroups: ["Hamstrings", "Glutes", "Back", "Traps"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Sumo Deadlift", category: .powerlifting, muscleGroups: ["Glutes", "Adductors", "Quads", "Back"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Paused Squat", category: .powerlifting, muscleGroups: ["Quads", "Glutes", "Core"], equipment: "Barbell, Squat rack", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Paused Bench Press", category: .powerlifting, muscleGroups: ["Chest", "Triceps", "Shoulders"], equipment: "Barbell, Bench", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Overhead Press", category: .powerlifting, muscleGroups: ["Shoulders", "Triceps", "Core"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Front Squat", category: .powerlifting, muscleGroups: ["Quads", "Core", "Upper Back"], equipment: "Barbell, Squat rack", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Romanian Deadlift (Barbell)", category: .powerlifting, muscleGroups: ["Hamstrings", "Glutes", "Lower Back"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Good Morning", category: .powerlifting, muscleGroups: ["Lower Back", "Hamstrings", "Glutes"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Box Squat", category: .powerlifting, muscleGroups: ["Quads", "Glutes", "Hamstrings"], equipment: "Barbell, Box", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Rack Pull", category: .powerlifting, muscleGroups: ["Traps", "Back", "Glutes"], equipment: "Barbell, Power rack", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Close Grip Bench Press", category: .powerlifting, muscleGroups: ["Triceps", "Chest"], equipment: "Barbell, Bench", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Pendlay Row", category: .powerlifting, muscleGroups: ["Back", "Biceps", "Rear Deltoid"], equipment: "Barbell", isCustom: false, isGlobal: true),

        // CROSSFIT
        Exercise(id: UUID(), name: "Thruster", category: .crossfit, muscleGroups: ["Quads", "Shoulders", "Triceps", "Core"], equipment: "Barbell or Dumbbells", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Power Clean", category: .crossfit, muscleGroups: ["Full Body", "Hamstrings", "Traps"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Kettlebell Swing", category: .crossfit, muscleGroups: ["Glutes", "Hamstrings", "Core", "Shoulders"], equipment: "Kettlebell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Box Jump", category: .crossfit, muscleGroups: ["Quads", "Glutes", "Calves"], equipment: "Box", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Double Under", category: .crossfit, muscleGroups: ["Calves", "Coordination"], equipment: "Jump rope", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Toes to Bar", category: .crossfit, muscleGroups: ["Core", "Hip Flexors", "Lats"], equipment: "Pull-up bar", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Muscle-up", category: .crossfit, muscleGroups: ["Back", "Chest", "Triceps", "Biceps"], equipment: "Rings or Pull-up bar", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Wall Ball", category: .crossfit, muscleGroups: ["Quads", "Shoulders", "Core"], equipment: "Medicine ball", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Rope Climb", category: .crossfit, muscleGroups: ["Back", "Biceps", "Core"], equipment: "Rope", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Handstand Push-up", category: .crossfit, muscleGroups: ["Shoulders", "Triceps", "Core"], equipment: "Wall", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Snatch", category: .crossfit, muscleGroups: ["Full Body", "Shoulders", "Hips"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Clean and Jerk", category: .crossfit, muscleGroups: ["Full Body"], equipment: "Barbell", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "GHD Sit-up", category: .crossfit, muscleGroups: ["Core", "Hip Flexors"], equipment: "GHD machine", isCustom: false, isGlobal: true),
        Exercise(id: UUID(), name: "Rowing (Ergometer)", category: .crossfit, muscleGroups: ["Back", "Legs", "Core", "Arms"], equipment: "Rowing machine", isCustom: false, isGlobal: true)
    ]
}
