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

    // scheduled_date comes back as "yyyy-MM-dd" (PostgreSQL DATE type),
    // while started_at / ended_at come back as ISO8601 TIMESTAMPTZ strings.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        planId = try container.decodeIfPresent(UUID.self, forKey: .planId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""

        // Decode DATE-only string "yyyy-MM-dd"
        let dateString = try container.decode(String.self, forKey: .scheduledDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        guard let parsed = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .scheduledDate, in: container, debugDescription: "Cannot parse date: \(dateString)")
        }
        scheduledDate = parsed

        // Decode optional TIMESTAMPTZ fields — try ISO8601 with and without fractional seconds
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]

        if let s = try container.decodeIfPresent(String.self, forKey: .startedAt) {
            startedAt = iso.date(from: s) ?? isoPlain.date(from: s)
        } else {
            startedAt = nil
        }
        if let e = try container.decodeIfPresent(String.self, forKey: .endedAt) {
            endedAt = iso.date(from: e) ?? isoPlain.date(from: e)
        } else {
            endedAt = nil
        }
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
