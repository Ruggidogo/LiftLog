import Foundation
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var sessions: [Session] = []
    @Published var currentMonth: Date = Date()
    @Published var isWeekView: Bool = false
    @Published var isLoading = false
    @Published var error: AppError?

    private var userId: UUID?

    var sessionsByDate: [Date: [Session]] {
        Dictionary(grouping: sessions) { $0.scheduledDate.startOfDay }
    }

    var daysInCurrentMonth: [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)
        let days = DateHelper.daysInMonth(year: year, month: month)
        return (1...days).map { DateHelper.date(year: year, month: month, day: $0) }
    }

    var weekDays: [Date] {
        DateHelper.weekDates(containing: selectedDate)
    }

    var firstWeekdayOffset: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)
        return DateHelper.firstWeekdayOfMonth(year: year, month: month)
    }

    var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    func load(userId: UUID) async {
        self.userId = userId
        isLoading = true
        defer { isLoading = false }
        do {
            let calendar = Calendar.current
            let start = calendar.date(byAdding: .month, value: -1, to: currentMonth.startOfDay)!
            let end = calendar.date(byAdding: .month, value: 2, to: currentMonth.startOfDay)!
            sessions = try await SessionService.shared.fetchSessions(for: userId, from: start, to: end)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    func sessionsFor(date: Date) -> [Session] {
        sessionsByDate[date.startOfDay] ?? []
    }

    func hasSession(on date: Date) -> Bool {
        !sessionsFor(date: date).isEmpty
    }

    func createSession(on date: Date, planId: UUID?, userId: UUID) async throws -> Session {
        var session = Session(userId: userId, planId: planId, scheduledDate: date)
        session = try await SessionService.shared.createSession(session)
        sessions.append(session)
        return session
    }

    func deleteSession(_ session: Session) async {
        do {
            try await SessionService.shared.deleteSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }
}
