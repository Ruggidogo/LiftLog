import Foundation
import SwiftUI

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
}

struct WeeklyCount: Identifiable {
    let id = UUID()
    let weekStart: Date
    let count: Int
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case month30 = "30d"
    case month3 = "3m"
    case month6 = "6m"
    case all = "All"

    var id: String { rawValue }
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var allSets: [SessionSet] = []
    @Published var selectedExercise: Exercise?
    @Published var selectedPeriod: StatsPeriod = .month3
    @Published var isLoading = false
    @Published var error: AppError?

    var progressionData: [WeightDataPoint] {
        guard let exercise = selectedExercise else { return [] }
        let cutoff = cutoffDate(for: selectedPeriod)
        let filtered = allSets
            .filter { $0.exerciseId == exercise.id && $0.completed && !$0.isBodyweight }
            .filter { set in
                guard let session = sessions.first(where: { _ in true }) else { return true }
                return session.scheduledDate >= cutoff
            }

        let sessionSetsMap = Dictionary(grouping: filtered) { $0.sessionId }
        return sessionSetsMap.compactMap { (sessionId, sets) -> WeightDataPoint? in
            guard let session = sessions.first(where: { $0.id == sessionId }),
                  let maxWeight = sets.map({ $0.weightKg }).max() else { return nil }
            return WeightDataPoint(date: session.scheduledDate, maxWeight: maxWeight)
        }.sorted { $0.date < $1.date }
    }

    var progressionDataFiltered: [WeightDataPoint] {
        let cutoff = cutoffDate(for: selectedPeriod)
        guard let exercise = selectedExercise else { return [] }

        let sessionMap = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
        let filtered = allSets
            .filter { $0.exerciseId == exercise.id && $0.completed && !$0.isBodyweight }
            .filter { set in
                guard let session = sessionMap[set.sessionId] else { return false }
                return session.scheduledDate >= cutoff
            }

        let grouped = Dictionary(grouping: filtered) { $0.sessionId }
        return grouped.compactMap { (sessionId, sets) -> WeightDataPoint? in
            guard let session = sessionMap[sessionId],
                  let maxWeight = sets.map({ $0.weightKg }).max() else { return nil }
            return WeightDataPoint(date: session.scheduledDate, maxWeight: maxWeight)
        }.sorted { $0.date < $1.date }
    }

    var weeklySessionCounts: [WeeklyCount] {
        let weeks = DateHelper.last12Weeks()
        let calendar = Calendar.current
        return weeks.map { weekStart in
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let count = sessions.filter {
                $0.scheduledDate >= weekStart && $0.scheduledDate <= weekEnd && $0.endedAt != nil
            }.count
            return WeeklyCount(weekStart: weekStart, count: count)
        }
    }

    var heatmapDays: [Date] {
        DateHelper.last6MonthsDays()
    }

    func sessionsOnDay(_ date: Date) -> Int {
        sessions.filter { $0.scheduledDate.isSameDay(as: date) && $0.endedAt != nil }.count
    }

    var currentStreak: Int {
        var streak = 0
        var date = Date().startOfDay
        let calendar = Calendar.current
        while true {
            if sessions.contains(where: { $0.scheduledDate.isSameDay(as: date) && $0.endedAt != nil }) {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return streak
    }

    var longestStreak: Int {
        let sorted = sessions.filter { $0.endedAt != nil }.map { $0.scheduledDate.startOfDay }.sorted()
        var longest = 0
        var current = 0
        var prev: Date?
        for date in sorted {
            if let p = prev, Calendar.current.dateComponents([.day], from: p, to: date).day == 1 {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            prev = date
        }
        return longest
    }

    var totalSessions: Int { sessions.filter { $0.endedAt != nil }.count }

    var totalVolume: Double {
        allSets.filter { $0.completed && !$0.isBodyweight }.reduce(0) { $0 + $1.volume }
    }

    var currentMonthMetrics: MonthMetrics {
        metricsFor(month: Date())
    }

    var previousMonthMetrics: MonthMetrics {
        let prev = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return metricsFor(month: prev)
    }

    func metricsFor(month: Date) -> MonthMetrics {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        let monthSessions = sessions.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.scheduledDate)
            return c.year == comps.year && c.month == comps.month && $0.endedAt != nil
        }
        let sessionIds = Set(monthSessions.map { $0.id })
        let monthSets = allSets.filter { sessionIds.contains($0.sessionId) && $0.completed && !$0.isBodyweight }
        let volume = monthSets.reduce(0.0) { $0 + $1.volume }
        let avgDuration = monthSessions.compactMap { $0.duration }.reduce(0, +) / Double(max(monthSessions.count, 1))
        let muscleGroups = monthSets.compactMap { $0.exercise?.muscleGroups }.flatMap { $0 }
        let topMuscle = Dictionary(grouping: muscleGroups) { $0 }.max(by: { $0.value.count < $1.value.count })?.key ?? "-"
        return MonthMetrics(sessionCount: monthSessions.count, totalVolume: volume, avgDuration: avgDuration, topMuscle: topMuscle)
    }

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await SessionService.shared.fetchSessions(for: userId)
            allSets = try await SessionService.shared.fetchAllSets(for: userId)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    private func cutoffDate(for period: StatsPeriod) -> Date {
        let calendar = Calendar.current
        switch period {
        case .month30: return calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        case .month3: return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .month6: return calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .all: return Date.distantPast
        }
    }
}

struct MonthMetrics {
    let sessionCount: Int
    let totalVolume: Double
    let avgDuration: TimeInterval
    let topMuscle: String
}
