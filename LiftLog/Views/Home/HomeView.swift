import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var calendarVM = CalendarViewModel()
    @State private var showActiveSession = false
    @State private var activeSession: Session?
    @State private var activePlanExercises: [PlanExercise] = []

    private var todaySessions: [Session] {
        calendarVM.sessionsFor(date: Date())
    }

    private var weekSessions: [Date: Bool] {
        let days = DateHelper.weekDates(containing: Date())
        return Dictionary(uniqueKeysWithValues: days.map { date in
            (date, calendarVM.hasSession(on: date))
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingSection
                    todayCard
                    weeklyStreakSection
                    quickActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await calendarVM.load(userId: userId)
                }
            }
        }
        .fullScreenCover(isPresented: $showActiveSession) {
            if let session = activeSession {
                let vm = ActiveSessionViewModel(session: session)
                ActiveSessionView(viewModel: vm, planExercises: activePlanExercises)
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: LocalizedStringKey(DateHelper.greetingKey())))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(authViewModel.currentUser?.fullName.components(separatedBy: " ").first ?? "Athlete")
                .font(.largeTitle.bold())
        }
        .padding(.top, 20)
    }

    private var todayCard: some View {
        Group {
            if todaySessions.isEmpty {
                EmptyTodayCard()
            } else if let session = todaySessions.first {
                TodaySessionCard(session: session) {
                    activeSession = session
                    showActiveSession = true
                }
            }
        }
    }

    private var weeklyStreakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home.weekly_streak"))
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(DateHelper.weekDates(containing: Date()), id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(date.weekdaySymbol)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(calendarVM.hasSession(on: date) ? Color.accentColor : Color(.systemFill))
                            .frame(width: 32, height: 32)
                            .overlay(
                                date.isToday ?
                                Circle().stroke(Color.accentColor, lineWidth: 2) : nil
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home.quick_actions"))
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: String(localized: "home.action.new_session"),
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    if let userId = authViewModel.currentUser?.id {
                        Task {
                            if let session = try? await calendarVM.createSession(on: Date(), planId: nil, userId: userId) {
                                activeSession = session
                                activePlanExercises = []
                                showActiveSession = true
                            }
                        }
                    }
                }

                QuickActionButton(
                    title: String(localized: "tab.plans"),
                    icon: "list.bullet.clipboard.fill",
                    color: .blue
                ) {}

                QuickActionButton(
                    title: String(localized: "exercise.library"),
                    icon: "book.fill",
                    color: .orange
                ) {}
            }
        }
    }
}

struct TodaySessionCard: View {
    let session: Session
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "home.today_session"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(session.endedAt != nil ? String(localized: "session.completed") : String(localized: "session.scheduled"))
                        .font(.headline)
                }
                Spacer()
                Image(systemName: session.endedAt != nil ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(session.endedAt != nil ? .green : .accentColor)
                    .font(.title2)
            }

            if session.endedAt == nil {
                Button(action: onStart) {
                    Text(String(localized: "button.start_workout"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyTodayCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.title)
                .foregroundColor(.secondary)
            Text(String(localized: "home.no_session_today"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
