import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleSessionReminders(sessions: [Session], settings: NotificationSettings) {
        guard settings.enabled else { return }
        center.removePendingNotificationRequests(withIdentifiers: sessions.map { "session-\($0.id)" })

        let timeComponents = DateHelper.timeFromString(settings.reminderTime)
        let message = settings.customMessage.isEmpty
            ? String(localized: "notification.default_message")
            : settings.customMessage

        for session in sessions {
            var triggerComponents = Calendar.current.dateComponents([.year, .month, .day], from: session.scheduledDate)
            triggerComponents.hour = timeComponents.hour
            triggerComponents.minute = timeComponents.minute

            let content = UNMutableNotificationContent()
            content.title = "LiftLog"
            content.body = message
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "session-\(session.id)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    func scheduleInactivityAlert(lastSessionDate: Date?) {
        center.removePendingNotificationRequests(withIdentifiers: ["inactivity-alert"])

        let threshold = Constants.Notifications.inactivityDays
        guard let last = lastSessionDate else {
            fireInactivityAlert()
            return
        }
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        if daysSince >= threshold {
            fireInactivityAlert()
        }
    }

    private func fireInactivityAlert() {
        let content = UNMutableNotificationContent()
        content.title = "LiftLog"
        content.body = String(localized: "notification.inactivity")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity-alert", content: content, trigger: trigger)
        center.add(request)
    }

    func rescheduleAll(sessions: [Session], settings: NotificationSettings, lastSessionDate: Date?) {
        scheduleSessionReminders(sessions: sessions, settings: settings)
        scheduleInactivityAlert(lastSessionDate: lastSessionDate)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
