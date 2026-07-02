import Foundation
import Supabase

final class SessionService {
    static let shared = SessionService()
    private let client = SupabaseService.shared.client

    private init() {}

    func fetchSessions(for userId: UUID) async throws -> [Session] {
        let response: [Session] = try await client
            .from(Constants.Tables.sessions)
            .select()
            .eq("user_id", value: userId)
            .order("scheduled_date", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchSessions(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [Session] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let response: [Session] = try await client
            .from(Constants.Tables.sessions)
            .select()
            .eq("user_id", value: userId)
            .gte("scheduled_date", value: formatter.string(from: startDate))
            .lte("scheduled_date", value: formatter.string(from: endDate))
            .order("scheduled_date")
            .execute()
            .value
        return response
    }

    func createSession(_ session: Session) async throws -> Session {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        struct SessionInsert: Encodable {
            let id: String
            let user_id: String
            let plan_id: String?
            let scheduled_date: String
            let notes: String
        }
        let payload = SessionInsert(
            id: session.id.uuidString,
            user_id: session.userId.uuidString,
            plan_id: session.planId?.uuidString,
            scheduled_date: formatter.string(from: session.scheduledDate),
            notes: session.notes
        )
        let response: Session = try await client
            .from(Constants.Tables.sessions)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func startSession(id: UUID) async throws {
        struct StartUpdate: Encodable { let started_at: String }
        try await client
            .from(Constants.Tables.sessions)
            .update(StartUpdate(started_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: id)
            .execute()
    }

    func endSession(id: UUID, notes: String) async throws {
        struct EndUpdate: Encodable { let ended_at: String; let notes: String }
        try await client
            .from(Constants.Tables.sessions)
            .update(EndUpdate(ended_at: ISO8601DateFormatter().string(from: Date()), notes: notes))
            .eq("id", value: id)
            .execute()
    }

    func deleteSession(id: UUID) async throws {
        try await client
            .from(Constants.Tables.sessions)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func fetchSets(for sessionId: UUID) async throws -> [SessionSet] {
        let response: [SessionSet] = try await client
            .from(Constants.Tables.sessionSets)
            .select("*, exercises(*)")
            .eq("session_id", value: sessionId)
            .order("set_number")
            .execute()
            .value
        return response
    }

    func saveSets(_ sets: [SessionSet], sessionId: UUID) async throws {
        try await client
            .from(Constants.Tables.sessionSets)
            .delete()
            .eq("session_id", value: sessionId)
            .execute()
        guard !sets.isEmpty else { return }
        struct SetInsert: Encodable {
            let id: String
            let session_id: String
            let exercise_id: String
            let set_number: Int
            let reps_done: Int
            let weight_kg: Double
            let is_bodyweight: Bool
            let completed: Bool
        }
        let payloads = sets.map { set in
            SetInsert(
                id: set.id.uuidString,
                session_id: sessionId.uuidString,
                exercise_id: set.exerciseId.uuidString,
                set_number: set.setNumber,
                reps_done: set.repsDone,
                weight_kg: set.weightKg,
                is_bodyweight: set.isBodyweight,
                completed: set.completed
            )
        }
        try await client
            .from(Constants.Tables.sessionSets)
            .insert(payloads)
            .execute()
    }

    func fetchAllSets(for userId: UUID) async throws -> [SessionSet] {
        let sessions = try await fetchSessions(for: userId)
        guard !sessions.isEmpty else { return [] }
        let response: [SessionSet] = try await client
            .from(Constants.Tables.sessionSets)
            .select("*, exercises(*)")
            .in("session_id", values: sessions.map { $0.id.uuidString })
            .eq("completed", value: true)
            .execute()
            .value
        return response
    }
}
