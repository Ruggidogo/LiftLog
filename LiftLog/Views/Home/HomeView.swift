import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var calendarVM = CalendarViewModel()
    @State private var showActiveSession = false
    @State private var activeSession: Session?
    @State private var activePlanExercises: [PlanExercise] = []

    private var todaySessions: [Session] { calendarVM.sessionsFor(date: Date()) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

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
                Text(LocalizedStringKey(DateHelper.greetingKey()))
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
        BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "This Week")

                HStack(spacing: 6) {
                    ForEach(DateHelper.weekDates(containing: Date()), id: \.self) { date in
                        VStack(spacing: 6) {
                            Text(date.weekdaySymbol)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)
                            ZStack {
                                Circle()
                                    .fill(calendarVM.hasSession(on: date) ? Color.brand : Color.surfaceHigh)
                                    .frame(width: 34, height: 34)
                                if date.isToday {
                                    Circle()
                                        .stroke(Color.brand, lineWidth: 2)
                                        .frame(width: 34, height: 34)
                                }
                                if calendarVM.hasSession(on: date) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions")

            HStack(spacing: 12) {
                QuickActionButton(title: "New Session", icon: "plus.circle.fill", color: .brand) {
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
                QuickActionButton(title: "My Plans", icon: "list.bullet.clipboard.fill", color: Color(red: 0.4, green: 0.6, blue: 1.0)) {}
                QuickActionButton(title: "Exercises", icon: "book.fill", color: Color(red: 1.0, green: 0.6, blue: 0.2)) {}
            }
        }
    }
}

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
                    ZStack {
                        Circle()
                            .fill(session.endedAt != nil ? Color.brand.opacity(0.2) : Color.surfaceHigh)
                            .frame(width: 44, height: 44)
                        Image(systemName: session.endedAt != nil ? "checkmark" : "bolt.fill")
                            .foregroundColor(session.endedAt != nil ? .brand : .textSecondary)
                            .font(.system(size: 16, weight: .semibold))
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
    var body: some View {
        BrandCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.brand.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 22))
                        .foregroundColor(.brand)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("No session today")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Tap + to start a free workout")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
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
