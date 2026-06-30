import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var showAddExercise = false
    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilter
                exerciseList
            }
            .searchable(text: $viewModel.searchText, prompt: String(localized: "exercise.search"))
            .navigationTitle(String(localized: "exercise.library"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView(viewModel: viewModel)
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailSheet(exercise: exercise)
            }
        }
        .errorAlert(error: $viewModel.error)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: String(localized: "category.all"), isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(ExerciseCategory.allCases) { category in
                    FilterChip(title: category.displayName, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var exerciseList: some View {
        Group {
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(String(localized: "exercise.empty"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filtered) { exercise in
                    ExerciseListRow(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedExercise = exercise }
                        .swipeActions(edge: .trailing) {
                            if exercise.isCustom {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteExercise(exercise) }
                                } label: {
                                    Label(String(localized: "button.delete"), systemImage: "trash")
                                }
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseListRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.category.icon)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.subheadline.bold())
                    if exercise.isCustom {
                        Text(String(localized: "exercise.custom_badge"))
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                Text(exercise.muscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(String(localized: "exercise.category"), value: exercise.category.displayName)
                    LabeledContent(String(localized: "exercise.equipment"), value: exercise.equipment.isEmpty ? "-" : exercise.equipment)
                }

                Section(String(localized: "exercise.muscles")) {
                    ForEach(exercise.muscleGroups, id: \.self) { muscle in
                        Text(muscle)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.done")) { dismiss() }
                }
            }
        }
    }
}

struct AddExerciseView: View {
    @ObservedObject var viewModel: ExerciseLibraryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var category: ExerciseCategory = .weights
    @State private var muscleGroupInput = ""
    @State private var equipment = ""
    @State private var error: AppError?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "exercise.name"), text: $name)
                    Picker(String(localized: "exercise.category"), selection: $category) {
                        ForEach(ExerciseCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    TextField(String(localized: "exercise.muscles_hint"), text: $muscleGroupInput)
                    TextField(String(localized: "exercise.equipment"), text: $equipment)
                }
            }
            .navigationTitle(String(localized: "exercise.add_custom"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.save")) {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .errorAlert(error: $error)
    }

    private func save() {
        guard let userId = authViewModel.currentUser?.id else { return }
        let muscles = muscleGroupInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        Task {
            do {
                try await viewModel.addCustomExercise(name: name, category: category, muscleGroups: muscles, equipment: equipment, userId: userId)
                dismiss()
            } catch {
                self.error = .network(error.localizedDescription)
            }
        }
    }
}
