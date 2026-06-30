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
        let payload: [String: AnyJSON] = [
            "id": .string(session.id.uuidString),
            "user_id": .string(session.userId.uuidString),
            "plan_id": session.planId.map { .string($0.uuidString) } ?? .null,
            "scheduled_date": .string(formatter.string(from: session.scheduledDate)),
            "notes": .string(session.notes)
        ]
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
        try await client
            .from(Constants.Tables.sessions)
            .update(["started_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id)
            .execute()
    }

    func endSession(id: UUID, notes: String) async throws {
        let fields: [String: AnyJSON] = [
            "ended_at": .string(ISO8601DateFormatter().string(from: Date())),
            "notes": .string(notes)
        ]
        try await client
            .from(Constants.Tables.sessions)
            .update(fields)
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
        let payloads: [[String: AnyJSON]] = sets.map { set in
            [
                "id": .string(set.id.uuidString),
                "session_id": .string(sessionId.uuidString),
                "exercise_id": .string(set.exerciseId.uuidString),
                "set_number": .double(Double(set.setNumber)),
                "reps_done": .double(Double(set.repsDone)),
                "weight_kg": .double(set.weightKg),
                "is_bodyweight": .bool(set.isBodyweight),
                "completed": .bool(set.completed)
            ]
        }
        try await client
            .from(Constants.Tables.sessionSets)
            .insert(payloads)
            .execute()
    }

    func fetchAllSets(for userId: UUID) async throws -> [SessionSet] {
        let sessions = try await fetchSessions(for: userId)
        guard !sessions.isEmpty else { return [] }
        let sessionIds = sessions.map { $0.id.uuidString }
        let response: [SessionSet] = try await client
            .from(Constants.Tables.sessionSets)
            .select("*, exercises(*)")
            .in("session_id", values: sessionIds)
            .eq("completed", value: true)
            .execute()
            .value
        return response
    }
}
