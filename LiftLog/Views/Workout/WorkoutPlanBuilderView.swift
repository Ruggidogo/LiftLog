import SwiftUI

struct WorkoutPlanBuilderView: View {
    @ObservedObject var viewModel: WorkoutPlanViewModel
    let existingPlan: WorkoutPlan?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var planName: String = ""
    @State private var selectedGoal: WorkoutGoal = .mixed
    @State private var selectedAssignee: UUID?
    @State private var showExercisePicker = false
    @State private var isSaving = false
    @State private var error: AppError?

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "plan.info")) {
                    TextField(String(localized: "plan.name"), text: $planName)
                    Picker(String(localized: "plan.goal"), selection: $selectedGoal) {
                        ForEach(WorkoutGoal.allCases) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }
                }

                if authViewModel.currentUser?.role == .pt && !viewModel.clients.isEmpty {
                    Section(String(localized: "plan.assign")) {
                        Picker(String(localized: "plan.assign_to"), selection: $selectedAssignee) {
                            Text(String(localized: "plan.no_assignment")).tag(UUID?.none)
                            ForEach(viewModel.clients) { client in
                                Text(client.fullName).tag(Optional(client.id))
                            }
                        }
                    }
                }

                Section(String(localized: "plan.exercises")) {
                    ForEach($viewModel.planExercises) { $planEx in
                        PlanExerciseRow(planExercise: $planEx)
                    }
                    .onDelete { viewModel.removeExercise(at: $0) }
                    .onMove { viewModel.moveExercise(from: $0, to: $1) }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label(String(localized: "plan.add_exercise"), systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(existingPlan == nil ? String(localized: "plan.new") : String(localized: "plan.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.save")) {
                        save()
                    }
                    .disabled(planName.isEmpty || isSaving)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .onAppear {
                if let plan = existingPlan {
                    planName = plan.name
                    selectedGoal = plan.goal
                    selectedAssignee = plan.assignedTo
                    viewModel.currentPlan = plan
                    Task { await viewModel.loadPlanExercises(for: plan.id) }
                } else {
                    viewModel.currentPlan = nil
                    viewModel.planExercises = []
                }
                if let userId = authViewModel.currentUser?.id,
                   authViewModel.currentUser?.role == .pt {
                    Task { await viewModel.loadClients(for: userId) }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    let planId = existingPlan?.id ?? UUID()
                    _ = viewModel.addExerciseToPlan(exercise, planId: planId)
                }
            }
        }
        .errorAlert(error: $error)
    }

    private func save() {
        guard let userId = authViewModel.currentUser?.id else { return }
        isSaving = true
        Task {
            do {
                try await viewModel.savePlan(
                    name: planName,
                    goal: selectedGoal,
                    exercises: viewModel.planExercises,
                    assignedTo: selectedAssignee,
                    userId: userId
                )
                dismiss()
            } catch {
                self.error = .network(error.localizedDescription)
            }
            isSaving = false
        }
    }
}

struct PlanExerciseRow: View {
    @Binding var planExercise: PlanExercise
    @State private var showNotes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(planExercise.exercise?.name ?? String(localized: "exercise.unknown"))
                .font(.subheadline.bold())

            HStack(spacing: 20) {
                StepperField(label: String(localized: "plan.sets"), value: $planExercise.sets, range: 1...20)
                StepperField(label: String(localized: "plan.reps"), value: $planExercise.reps, range: 1...100)
                StepperField(label: String(localized: "plan.rest"), value: $planExercise.restSeconds, range: 0...600, step: 15)
            }

            if showNotes {
                TextField(String(localized: "plan.notes"), text: $planExercise.notes)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }

            Button {
                withAnimation { showNotes.toggle() }
            } label: {
                Text(showNotes ? String(localized: "plan.hide_notes") : String(localized: "plan.add_notes"))
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StepperField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Button { value = max(range.lowerBound, value - step) } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                Text("\(value)")
                    .font(.subheadline.bold())
                    .frame(minWidth: 28)
                Button { value = min(range.upperBound, value + step) } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
