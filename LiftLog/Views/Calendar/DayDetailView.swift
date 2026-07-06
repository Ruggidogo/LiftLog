import SwiftUI

struct DayDetailView: View {
    let date: Date
    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var planVM = WorkoutPlanViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showActiveSession = false
    @State private var activeSession: Session?
    @State private var activePlanExercises: [PlanExercise] = []
    @State private var showPlanPicker = false
    @State private var isCreating = false
    @State private var error: AppError?

    private var sessionsForDay: [Session] {
        viewModel.sessionsFor(date: date)
    }

    private var isToday: Bool { date.isToday }
    private var isPast: Bool { date.startOfDay < Date().startOfDay }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        dateHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if sessionsForDay.isEmpty {
                            emptyState
                        } else {
                            sessionsList
                        }

                        if !isPast || sessionsForDay.isEmpty {
                            createSection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.brand)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await planVM.loadPlans(for: userId)
                }
            }
            .sheet(isPresented: $showPlanPicker) {
                planPickerSheet
            }
        }
        .fullScreenCover(isPresented: $showActiveSession) {
            if let session = activeSession {
                let vm = ActiveSessionViewModel(session: session)
                ActiveSessionView(viewModel: vm, planExercises: activePlanExercises)
            }
        }
        .errorAlert(error: $error)
    }

    // MARK: - Header

    private var dateHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.brand)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(date, format: .dateTime.day().month(.wide).year())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            if isToday {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.brand.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.surface)
                    .frame(width: 72, height: 72)
                Image(systemName: isPast ? "moon.zzz.fill" : "calendar.badge.plus")
                    .font(.system(size: 28))
                    .foregroundColor(.textSecondary)
            }
            Text(isPast ? "No workout recorded" : "Nothing planned yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text(isPast ? "You didn't log a session this day." : "Add a session below to plan your training.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        VStack(spacing: 10) {
            ForEach(sessionsForDay) { session in
                SessionRowCard(session: session) {
                    activeSession = session
                    if let planId = session.planId {
                        Task {
                            activePlanExercises = (try? await WorkoutService.shared.fetchPlanExercises(for: planId)) ?? []
                            showActiveSession = true
                        }
                    } else {
                        activePlanExercises = []
                        showActiveSession = true
                    }
                } onDelete: {
                    Task { await viewModel.deleteSession(session) }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Create Section

    private var createSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !sessionsForDay.isEmpty {
                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)
                    .padding(.horizontal, 20)
            }

            Text(sessionsForDay.isEmpty ? "Add a session" : "Add another session")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 20)

            // Plan-based session
            Button {
                showPlanPicker = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.brand.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(.brand)
                            .font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From a plan")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("Pick one of your workout plans")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            // Quick session
            Button {
                createQuickSession(planId: nil)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.brand.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.brand)
                            .font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick session")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("Start a free workout right away")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    if isCreating {
                        ProgressView().tint(.brand)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(16)
                .background(Color.brand.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brand.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isCreating)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Plan Picker Sheet

    private var planPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

                if planVM.plans.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary)
                        Text("No plans yet")
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(planVM.plans) { plan in
                                Button {
                                    showPlanPicker = false
                                    createQuickSession(planId: plan.id)
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.brand.opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "figure.strengthtraining.traditional")
                                                .foregroundColor(.brand)
                                                .font(.system(size: 18))
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(plan.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.textPrimary)
                                            Text(plan.goal.displayName)
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(16)
                                    .background(Color.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Select Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPlanPicker = false }
                        .foregroundColor(.brand)
                }
            }
        }
    }

    // MARK: - Actions

    private func createQuickSession(planId: UUID?) {
        guard let userId = authViewModel.currentUser?.id else { return }
        isCreating = true
        Task {
            do {
                let session = try await viewModel.createSession(on: date, planId: planId, userId: userId)
                if let planId {
                    activePlanExercises = (try? await WorkoutService.shared.fetchPlanExercises(for: planId)) ?? []
                } else {
                    activePlanExercises = []
                }
                activeSession = session
                showActiveSession = true
            } catch {
                self.error = .network(error.localizedDescription)
            }
            isCreating = false
        }
    }
}

// MARK: - Session Row Card

struct SessionRowCard: View {
    let session: Session
    let onStart: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(session.endedAt != nil ? Color.brand.opacity(0.2) : Color.surfaceHigh)
                    .frame(width: 44, height: 44)
                Image(systemName: session.endedAt != nil ? "checkmark" : "bolt.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(session.endedAt != nil ? .brand : .textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.endedAt != nil ? "Completed" : "Scheduled")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                if let duration = session.duration {
                    Text(duration.formattedHoursDuration)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            if session.endedAt == nil {
                Button(action: onStart) {
                    Text("Start")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.brand)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
