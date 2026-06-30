import Foundation
import SwiftUI

@MainActor
final class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ExerciseCategory? = nil
    @Published var isLoading = false
    @Published var error: AppError?

    var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroups.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || exercise.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            exercises = try await ExerciseService.shared.fetchExercises(forUser: userId)
            if exercises.isEmpty {
                exercises = ExerciseService.seedExercises
            }
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
