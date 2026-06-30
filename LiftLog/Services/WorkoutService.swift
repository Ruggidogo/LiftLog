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
        let payload: [String: AnyJSON] = [
            "id": .string(plan.id.uuidString),
            "name": .string(plan.name),
            "goal": .string(plan.goal.rawValue),
            "created_by": .string(plan.createdBy.uuidString),
            "assigned_to": plan.assignedTo.map { .string($0.uuidString) } ?? .null,
            "created_at": .string(ISO8601DateFormatter().string(from: plan.createdAt))
        ]
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
        let fields: [String: AnyJSON] = [
            "name": .string(plan.name),
            "goal": .string(plan.goal.rawValue),
            "assigned_to": plan.assignedTo.map { .string($0.uuidString) } ?? .null
        ]
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
        let payloads: [[String: AnyJSON]] = exercises.enumerated().map { index, ex in
            [
                "id": .string(ex.id.uuidString),
                "plan_id": .string(planId.uuidString),
                "exercise_id": .string(ex.exerciseId.uuidString),
                "sets": .double(Double(ex.sets)),
                "reps": .double(Double(ex.reps)),
                "rest_seconds": .double(Double(ex.restSeconds)),
                "sort_order": .double(Double(index)),
                "notes": .string(ex.notes)
            ]
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
        let clientIds = ptClients.map { $0.clientId.uuidString }.joined(separator: ",")
        let users: [AppUser] = try await client
            .from(Constants.Tables.users)
            .select()
            .in("id", values: ptClients.map { $0.clientId.uuidString })
            .execute()
            .value
        _ = clientIds
        return users
    }

    func addClient(ptId: UUID, clientEmail: String) async throws {
        let users: [AppUser] = try await client
            .from(Constants.Tables.users)
            .select()
            .eq("email", value: clientEmail)
            .execute()
            .value
        guard let client_user = users.first else {
            throw AppError.validation(String(localized: "error.client_not_found"))
        }
        let payload: [String: AnyJSON] = [
            "id": .string(UUID().uuidString),
            "pt_id": .string(ptId.uuidString),
            "client_id": .string(client_user.id.uuidString)
        ]
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
