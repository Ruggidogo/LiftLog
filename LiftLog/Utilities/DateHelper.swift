import Foundation

enum DateHelper {
    static func daysInMonth(year: Int, month: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar.current
        let date = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }

    static func firstWeekdayOfMonth(year: Int, month: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let calendar = Calendar.current
        let date = calendar.date(from: components)!
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    static func weekDates(containing date: Date) -> [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: date.startOfDay) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    static func last12Weeks() -> [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<12).reversed().compactMap {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: today)
        }
    }

    static func last6MonthsDays() -> [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let start = calendar.date(byAdding: .month, value: -6, to: today) else { return [] }
        var dates: [Date] = []
        var current = start
        while current <= today {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? today
        }
        return dates
    }

    static func greetingKey() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "greeting.morning"
        case 12..<17: return "greeting.afternoon"
        default: return "greeting.evening"
        }
    }

    static func timeFromString(_ timeString: String) -> DateComponents {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        var components = DateComponents()
        components.hour = parts.first ?? 8
        components.minute = parts.count > 1 ? parts[1] : 0
        return components
    }
}
