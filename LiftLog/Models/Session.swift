import Foundation

struct Session: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var planId: UUID?
    var scheduledDate: Date
    var startedAt: Date?
    var endedAt: Date?
    var notes: String

    var duration: TimeInterval? {
        guard let start = startedAt, let end = endedAt else { return nil }
        return end.timeIntervalSince(start)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planId = "plan_id"
        case scheduledDate = "scheduled_date"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case notes
    }

    init(id: UUID = UUID(), userId: UUID, planId: UUID? = nil, scheduledDate: Date = Date(), startedAt: Date? = nil, endedAt: Date? = nil, notes: String = "") {
        self.id = id
        self.userId = userId
        self.planId = planId
        self.scheduledDate = scheduledDate
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
    }
}
