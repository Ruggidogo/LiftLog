import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var calendarVM = CalendarViewModel()
    @State private var showActiveSession = false
    @State private var activeSession: Session?
    @State private var activePlanExercises: [PlanExercise] = []
    @State private var selectedWeekDay: Date?

    private var todaySessions: [Session] { calendarVM.sessionsFor(date: Date()) }

    private var monthSessionCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return calendarVM.sessions.filter {
            $0.endedAt != nil &&
            calendar.component(.month, from: $0.scheduledDate) == calendar.component(.month, from: now) &&
            calendar.component(.year, from: $0.scheduledDate) == calendar.component(.year, from: now)
        }.count
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date().startOfDay
        while true {
            if calendarVM.sessionsFor(date: checkDate).contains(where: { $0.endedAt != nil }) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        greetingSection
                        statsRow
                        todayCard
                        weeklyStreakSection
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(DateHelper.greeting())
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                Text(authViewModel.currentUser?.fullName.components(separatedBy: " ").first ?? "Athlete")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            LiftLogLogoView(size: 44)
        }
        .padding(.top, 56)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                value: "\(currentStreak)",
                label: "Day Streak",
                icon: PremiumIcon.flame(systemName: "flame.fill", size: 40)
            )
            StatPill(
                value: "\(monthSessionCount)",
                label: "This Month",
                icon: PremiumIcon.green(systemName: "calendar.badge.checkmark", size: 40)
            )
        }
    }

    private var todayCard: some View {
        Group {
            if todaySessions.isEmpty {
                EmptyTodayCard(lastSession: calendarVM.sessions.filter { $0.endedAt != nil }.sorted { $0.scheduledDate > $1.scheduledDate }.first) {
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
            } else if let session = todaySessions.first {
                TodaySessionCard(session: session) {
                    activeSession = session
                    showActiveSession = true
                }
            }
        }
    }

    private var weeklyStreakSection: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "This Week")

                HStack(spacing: 6) {
                    ForEach(DateHelper.weekDates(containing: Date()), id: \.self) { date in
                        let daySessions = calendarVM.sessionsFor(date: date)
                        let hasSession = !daySessions.isEmpty
                        let isSelected = selectedWeekDay?.startOfDay == date.startOfDay

                        VStack(spacing: 6) {
                            Text(date.weekdaySymbol)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedWeekDay = isSelected ? nil : (hasSession ? date : nil)
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(hasSession ? Color.brand : Color.surfaceHigh)
                                        .frame(width: 34, height: 34)
                                    if date.isToday && !hasSession {
                                        Circle()
                                            .stroke(Color.brand, lineWidth: 2)
                                            .frame(width: 34, height: 34)
                                    }
                                    if hasSession {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Session name tooltip for selected day
                if let selected = selectedWeekDay,
                   let session = calendarVM.sessionsFor(date: selected).first {
                    let label = session.notes.isEmpty ? "Workout" : session.notes
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 6, height: 6)
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(selected, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions")

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "New Session",
                    icon: PremiumIcon.green(systemName: "bolt.fill", size: 44)
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
                    title: "My Plans",
                    icon: PremiumIcon.blue(systemName: "list.bullet.clipboard.fill", size: 44)
                ) {}
                QuickActionButton(
                    title: "Exercises",
                    icon: PremiumIcon.flame(systemName: "dumbbell.fill", size: 44)
                ) {}
            }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let label: String
    let icon: PremiumIcon

    var body: some View {
        HStack(spacing: 12) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Today Cards

struct TodaySessionCard: View {
    let session: Session
    let onStart: () -> Void

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.brand)
                            .tracking(1.2)
                        Text(session.endedAt != nil ? "Completed" : "Scheduled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                    if session.endedAt != nil {
                        PremiumIcon.green(systemName: "checkmark.seal.fill", size: 44)
                    } else {
                        PremiumIcon.flame(systemName: "bolt.fill", size: 44)
                    }
                }

                if session.endedAt == nil {
                    BrandButton(title: "Start Workout", action: onStart)
                }
            }
        }
    }
}

struct EmptyTodayCard: View {
    let lastSession: Session?
    let onStart: () -> Void

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    PremiumIcon.green(systemName: "figure.strengthtraining.traditional", size: 52)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest day")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("No session scheduled — start one when you're ready.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let last = lastSession {
                    Divider().background(Color.divider)

                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        Text("Last workout: \(last.scheduledDate, style: .relative) ago")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                }

                BrandButton(title: "Start Free Workout", action: onStart)
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: PremiumIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                icon
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
