import SwiftUI
import UIKit

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        })
    }

    func errorAlert(error: Binding<AppError?>) -> some View {
        self.alert(isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(error.wrappedValue?.localizedDescription ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension Double {
    var formattedWeight: String {
        self == self.rounded() ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}

extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedHoursDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }

    var weekdaySymbol: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

enum AppError: LocalizedError {
    case network(String)
    case auth(String)
    case validation(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let msg): return msg
        case .auth(let msg): return msg
        case .validation(let msg): return msg
        case .unknown: return String(localized: "error.unknown")
        }
    }
}
