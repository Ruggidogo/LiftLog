import Foundation
import Supabase

final class WorkoutService {
    static let shared = WorkoutService()
    private let client = SupabaseService.shared.client

    private init() {}

    func fetchPlans(for userId: UUID) async throws -> [WorkoutPlan] {
        let response: [WorkoutPlan] = try await client
            .from(Constants.Tables.workoutPlans)
            .select()
            .or("created_by.eq.\(userId.uuidString),assigned_to.eq.\(userId.uuidString)")
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchPlan(id: UUID) async throws -> WorkoutPlan {
        let response: WorkoutPlan = try await client
            .from(Constants.Tables.workoutPlans)
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return response
    }

    func createPlan(_ plan: WorkoutPlan) async throws -> WorkoutPlan {
        struct PlanInsert: Encodable {
            let id: String
            let name: String
            let goal: String
            let created_by: String
            let assigned_to: String?
            let created_at: String
        }
        let payload = PlanInsert(
            id: plan.id.uuidString,
            name: plan.name,
            goal: plan.goal.rawValue,
            created_by: plan.createdBy.uuidString,
            assigned_to: plan.assignedTo?.uuidString,
            created_at: ISO8601DateFormatter().string(from: plan.createdAt)
        )
        let response: WorkoutPlan = try await client
            .from(Constants.Tables.workoutPlans)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updatePlan(_ plan: WorkoutPlan) async throws {
        struct PlanUpdate: Encodable {
            let name: String
            let goal: String
            let assigned_to: String?
        }
        let fields = PlanUpdate(
            name: plan.name,
            goal: plan.goal.rawValue,
            assigned_to: plan.assignedTo?.uuidString
        )
        try await client
            .from(Constants.Tables.workoutPlans)
            .update(fields)
            .eq("id", value: plan.id)
            .execute()
    }

    func deletePlan(id: UUID) async throws {
        try await client
            .from(Constants.Tables.workoutPlans)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func fetchPlanExercises(for planId: UUID) async throws -> [PlanExercise] {
        let response: [PlanExercise] = try await client
            .from(Constants.Tables.planExercises)
            .select("*, exercises(*)")
            .eq("plan_id", value: planId)
            .order("sort_order")
            .execute()
            .value
        return response
    }

    func savePlanExercises(_ exercises: [PlanExercise], for planId: UUID) async throws {
        try await client
            .from(Constants.Tables.planExercises)
            .delete()
            .eq("plan_id", value: planId)
            .execute()
        guard !exercises.isEmpty else { return }
        struct PlanExerciseInsert: Encodable {
            let id: String
            let plan_id: String
            let exercise_id: String
            let sets: Int
            let reps: Int
            let rest_seconds: Int
            let sort_order: Int
            let notes: String
        }
        let payloads = exercises.enumerated().map { index, ex in
            PlanExerciseInsert(
                id: ex.id.uuidString,
                plan_id: planId.uuidString,
                exercise_id: ex.exerciseId.uuidString,
                sets: ex.sets,
                reps: ex.reps,
                rest_seconds: ex.restSeconds,
                sort_order: index,
                notes: ex.notes
            )
        }
        try await client
            .from(Constants.Tables.planExercises)
            .insert(payloads)
            .execute()
    }

    func fetchClients(for ptId: UUID) async throws -> [AppUser] {
        let ptClients: [PTClient] = try await client
            .from(Constants.Tables.ptClients)
            .select()
            .eq("pt_id", value: ptId)
            .execute()
            .value
        guard !ptClients.isEmpty else { return [] }
        let users: [AppUser] = try await client
            .from(Constants.Tables.users)
            .select()
            .in("id", values: ptClients.map { $0.clientId.uuidString })
            .execute()
            .value
        return users
    }

    func addClient(ptId: UUID, clientEmail: String) async throws {
        let users: [AppUser] = try await client
            .from(Constants.Tables.users)
            .select()
            .eq("email", value: clientEmail)
            .execute()
            .value
        guard let clientUser = users.first else {
            throw AppError.validation(String(localized: "error.client_not_found"))
        }
        struct PTClientInsert: Encodable {
            let id: String
            let pt_id: String
            let client_id: String
        }
        let payload = PTClientInsert(
            id: UUID().uuidString,
            pt_id: ptId.uuidString,
            client_id: clientUser.id.uuidString
        )
        try await client
            .from(Constants.Tables.ptClients)
            .insert(payload)
            .execute()
    }

    func removeClient(ptId: UUID, clientId: UUID) async throws {
        try await client
            .from(Constants.Tables.ptClients)
            .delete()
            .eq("pt_id", value: ptId)
            .eq("client_id", value: clientId)
            .execute()
    }
}
