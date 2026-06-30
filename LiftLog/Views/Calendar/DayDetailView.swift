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
    @State private var selectedPlan: WorkoutPlan?
    @State private var showPlanPicker = false
    @State private var isCreating = false
    @State private var error: AppError?

    private var sessionsForDay: [Session] {
        viewModel.sessionsFor(date: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(date, style: .date)
                        .font(.title2.bold())
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if sessionsForDay.isEmpty {
                        emptyState
                    } else {
                        sessionsList
                    }

                    createSection
                }
                .padding(.bottom, 40)
            }
            .navigationTitle(String(localized: "day.detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.close")) { dismiss() }
                }
            }
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(String(localized: "day.no_session"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var sessionsList: some View {
        VStack(spacing: 12) {
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

    private var createSection: some View {
        VStack(spacing: 12) {
            Divider().padding(.horizontal, 20)
            Text(String(localized: "day.add_session"))
                .font(.headline)
                .padding(.horizontal, 20)

            Button {
                showPlanPicker = true
            } label: {
                Label(String(localized: "day.select_plan"), systemImage: "list.bullet.clipboard")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 20)

            Button {
                createQuickSession(planId: nil)
            } label: {
                Label(String(localized: "day.quick_session"), systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 20)
            .disabled(isCreating)
        }
    }

    private var planPickerSheet: some View {
        NavigationStack {
            List(planVM.plans) { plan in
                Button {
                    showPlanPicker = false
                    createQuickSession(planId: plan.id)
                } label: {
                    VStack(alignment: .leading) {
                        Text(plan.name).font(.headline).foregroundColor(.primary)
                        Text(plan.goal.displayName).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "day.select_plan"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { showPlanPicker = false }
                }
            }
        }
    }

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

struct SessionRowCard: View {
    let session: Session
    let onStart: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.endedAt != nil ? String(localized: "session.completed") : String(localized: "session.scheduled"))
                    .font(.subheadline.bold())
                if let duration = session.duration {
                    Text(duration.formattedHoursDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if session.endedAt == nil {
                Button(action: onStart) {
                    Text(String(localized: "button.start"))
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label(String(localized: "button.delete"), systemImage: "trash")
            }
        }
    }
}
