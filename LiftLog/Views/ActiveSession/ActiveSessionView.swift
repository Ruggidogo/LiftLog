import SwiftUI

struct ActiveSessionView: View {
    @ObservedObject var viewModel: ActiveSessionViewModel
    let planExercises: [PlanExercise]

    @Environment(\.dismiss) var dismiss
    @State private var showEndConfirm = false
    @State private var sessionNotes = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach($viewModel.exerciseEntries) { $entry in
                            if !entry.skipped {
                                ExerciseSectionView(
                                    entry: $entry,
                                    viewModel: viewModel
                                )
                            }
                        }
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                if viewModel.restTimerActive {
                    RestTimerOverlay(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: viewModel.restTimerActive)
            .navigationTitle(viewModel.elapsedTime.formattedDuration)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.end_session")) {
                        showEndConfirm = true
                    }
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if planExercises.isEmpty {
                    viewModel.setupFreeSession(exercises: [])
                } else {
                    viewModel.setup(planExercises: planExercises)
                }
            }
            .alert(String(localized: "session.end_confirm.title"), isPresented: $showEndConfirm) {
                Button(String(localized: "button.cancel"), role: .cancel) {}
                Button(String(localized: "button.end_session"), role: .destructive) {
                    Task { await viewModel.endSession(notes: sessionNotes) }
                }
            } message: {
                Text(String(localized: "session.end_confirm.message"))
            }
            .fullScreenCover(isPresented: $viewModel.showSummary) {
                SessionSummaryView(
                    viewModel: viewModel,
                    onDismiss: { dismiss() }
                )
            }
        }
        .errorAlert(error: $viewModel.error)
    }
}

struct ExerciseSectionView: View {
    @Binding var entry: SessionExerciseEntry
    @ObservedObject var viewModel: ActiveSessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.exercise.name)
                        .font(.headline)
                    Text(entry.exercise.muscleGroups.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        viewModel.skipExercise(entryId: entry.id)
                    } label: {
                        Label(String(localized: "session.skip"), systemImage: "forward.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }

            ForEach($entry.sets) { $set in
                SetRowView(
                    set: $set,
                    entryId: entry.id,
                    viewModel: viewModel
                )
            }

            Button {
                viewModel.addSet(to: entry.id)
            } label: {
                Label(String(localized: "session.add_set"), systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }

            if entry.notesExpanded {
                TextField(String(localized: "session.exercise_notes"), text: $entry.notes)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }

            Button {
                withAnimation { entry.notesExpanded.toggle() }
            } label: {
                Text(entry.notesExpanded ? String(localized: "session.hide_notes") : String(localized: "session.show_notes"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SetRowView: View {
    @Binding var set: SessionSet
    let entryId: UUID
    @ObservedObject var viewModel: ActiveSessionViewModel

    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        HStack(spacing: 10) {
            Text("#\(set.setNumber)")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .frame(width: 24)

            Toggle("", isOn: $set.isBodyweight)
                .labelsHidden()
                .scaleEffect(0.8)
                .onChange(of: set.isBodyweight) { _, val in
                    viewModel.updateSetBodyweight(entryId: entryId, setId: set.id, isBodyweight: val)
                }

            if !set.isBodyweight {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 64)
                    .onChange(of: weightText) { _, val in
                        if let w = Double(val) { viewModel.updateSetWeight(entryId: entryId, setId: set.id, weight: w) }
                    }
                Text("kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .onChange(of: repsText) { _, val in
                    if let r = Int(val) { viewModel.updateSetReps(entryId: entryId, setId: set.id, reps: r) }
                }
            Text(String(localized: "session.reps"))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                if set.completed {
                    viewModel.uncompleteSet(entryId: entryId, setId: set.id)
                } else {
                    let restSeconds = 90
                    viewModel.completeSet(entryId: entryId, setId: set.id, restSeconds: restSeconds)
                }
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(set.completed ? .green : .secondary)
            }
        }
        .strikethrough(set.completed, color: .secondary)
        .opacity(set.completed ? 0.7 : 1)
        .onAppear {
            repsText = set.repsDone > 0 ? "\(set.repsDone)" : ""
            weightText = set.weightKg > 0 ? set.weightKg.formattedWeight : ""
        }
    }
}

struct RestTimerOverlay: View {
    @ObservedObject var viewModel: ActiveSessionViewModel
    @State private var editingTime = false
    @State private var editSeconds = 90

    var progress: Double {
        guard viewModel.restTimerTotal > 0 else { return 0 }
        return Double(viewModel.restTimeRemaining) / Double(viewModel.restTimerTotal)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "session.rest"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "button.skip")) {
                    viewModel.dismissRestTimer()
                }
                .foregroundColor(.secondary)
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.restTimeRemaining)
                Text("\(viewModel.restTimeRemaining)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            .frame(width: 100, height: 100)

            Button {
                editSeconds = viewModel.restTimeRemaining
                editingTime = true
            } label: {
                Text(String(localized: "session.edit_rest"))
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .shadow(radius: 8)
        .alert(String(localized: "session.edit_rest"), isPresented: $editingTime) {
            TextField("90", value: $editSeconds, format: .number)
                .keyboardType(.numberPad)
            Button(String(localized: "button.ok")) {
                viewModel.editRestTimer(seconds: editSeconds)
            }
            Button(String(localized: "button.cancel"), role: .cancel) {}
        }
    }
}
