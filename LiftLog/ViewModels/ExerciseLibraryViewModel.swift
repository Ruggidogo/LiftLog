import Foundation
import SwiftUI

enum MuscleGroupFilter: String, CaseIterable, Identifiable {
    case all       = "All"
    case chest     = "Chest"
    case back      = "Back"
    case shoulders = "Shoulders"
    case arms      = "Arms"
    case legs      = "Legs"
    case core      = "Core"
    case fullBody  = "Full Body"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:       return "square.grid.2x2.fill"
        case .chest:     return "figure.arms.open"
        case .back:      return "figure.walk"
        case .shoulders: return "figure.wrestling"
        case .arms:      return "dumbbell.fill"
        case .legs:      return "figure.run"
        case .core:      return "bolt.heart.fill"
        case .fullBody:  return "figure.strengthtraining.traditional"
        }
    }

    var keywords: [String] {
        switch self {
        case .all:       return []
        case .chest:     return ["Chest", "Pecs"]
        case .back:      return ["Back", "Lats", "Traps", "Rhomboids", "Rear Deltoid"]
        case .shoulders: return ["Shoulders", "Deltoids", "Rotator"]
        case .arms:      return ["Biceps", "Triceps", "Forearms", "Brachialis"]
        case .legs:      return ["Quads", "Hamstrings", "Glutes", "Calves", "Hip Flexors", "Adductors"]
        case .core:      return ["Core", "Abs", "Obliques", "Lower Back"]
        case .fullBody:  return ["Full Body"]
        }
    }

    func matches(muscleGroups: [String]) -> Bool {
        guard self != .all else { return true }
        return muscleGroups.contains { muscle in
            keywords.contains { muscle.localizedCaseInsensitiveContains($0) }
        }
    }
}

@MainActor
final class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var searchText: String = ""
    @Published var selectedMuscleGroup: MuscleGroupFilter = .all
    @Published var isLoading = false
    @Published var error: AppError?

    var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroups.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscleGroup.matches(muscleGroups: exercise.muscleGroups)
            return matchesSearch && matchesMuscle
        }
    }

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            exercises = try await ExerciseService.shared.fetchExercises(forUser: userId)
            if exercises.isEmpty { exercises = ExerciseService.seedExercises }
        } catch {
            exercises = ExerciseService.seedExercises
        }
    }

    func addCustomExercise(name: String, category: ExerciseCategory, muscleGroups: [String], equipment: String, userId: UUID) async throws {
        let exercise = Exercise(id: UUID(), name: name, category: category, muscleGroups: muscleGroups, equipment: equipment, isCustom: true, isGlobal: false, createdBy: userId)
        let saved = try await ExerciseService.shared.createCustomExercise(exercise)
        exercises.append(saved)
    }

    func deleteExercise(_ exercise: Exercise) async {
        guard exercise.isCustom else { return }
        do {
            try await ExerciseService.shared.deleteExercise(id: exercise.id)
            exercises.removeAll { $0.id == exercise.id }
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }
}
