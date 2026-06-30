import Foundation
import SwiftUI

@MainActor
final class WorkoutPlanViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var currentPlan: WorkoutPlan?
    @Published var planExercises: [PlanExercise] = []
    @Published var clients: [AppUser] = []
    @Published var isLoading = false
    @Published var error: AppError?

    func loadPlans(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            plans = try await WorkoutService.shared.fetchPlans(for: userId)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func loadPlanExercises(for planId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            planExercises = try await WorkoutService.shared.fetchPlanExercises(for: planId)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func loadClients(for ptId: UUID) async {
        do {
            clients = try await WorkoutService.shared.fetchClients(for: ptId)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func savePlan(name: String, goal: WorkoutGoal, exercises: [PlanExercise], assignedTo: UUID?, userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        if var existing = currentPlan {
            existing.name = name
            existing.goal = goal
            existing.assignedTo = assignedTo
            try await WorkoutService.shared.updatePlan(existing)
            try await WorkoutService.shared.savePlanExercises(exercises, for: existing.id)
            if let idx = plans.firstIndex(where: { $0.id == existing.id }) {
                plans[idx] = existing
            }
        } else {
            let newPlan = WorkoutPlan(id: UUID(), name: name, goal: goal, createdBy: userId, assignedTo: assignedTo, createdAt: Date())
            let saved = try await WorkoutService.shared.createPlan(newPlan)
            try await WorkoutService.shared.savePlanExercises(exercises, for: saved.id)
            plans.insert(saved, at: 0)
        }
    }

    func deletePlan(_ plan: WorkoutPlan) async {
        do {
            try await WorkoutService.shared.deletePlan(id: plan.id)
            plans.removeAll { $0.id == plan.id }
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func addExerciseToPlan(_ exercise: Exercise, planId: UUID) -> PlanExercise {
        let pe = PlanExercise(planId: planId, exerciseId: exercise.id, sortOrder: planExercises.count, exercise: exercise)
        planExercises.append(pe)
        return pe
    }

    func removeExercise(at offsets: IndexSet) {
        planExercises.remove(atOffsets: offsets)
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        planExercises.move(fromOffsets: source, toOffset: destination)
    }
}
