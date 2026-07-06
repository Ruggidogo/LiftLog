import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var showAddExercise = false
    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()
                VStack(spacing: 0) {
                    muscleGroupFilter
                    exerciseList
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search exercises...")
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.brand)
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

    private var muscleGroupFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MuscleGroupFilter.allCases) { group in
                    let isSelected = viewModel.selectedMuscleGroup == group
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedMuscleGroup = group
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: group.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(group.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .black : .textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.brand : Color.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSelected ? Color.clear : Color.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.brandDeep)
    }

    private var exerciseList: some View {
        Group {
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                ProgressView().tint(.brand)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filtered.isEmpty {
                VStack(spacing: 14) {
                    PremiumIcon.green(systemName: "magnifyingglass", size: 56)
                    Text("No exercises found")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Try a different filter or search term")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filtered) { exercise in
                            ExerciseListRow(exercise: exercise)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedExercise = exercise }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
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
        HStack(spacing: 14) {
            ExerciseGifThumbnail(exercise: exercise, size: 68)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    if exercise.isCustom {
                        Text("Custom")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(exercise.muscleGroups.prefix(3), id: \.self) { muscle in
                            Text(muscle)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.brand)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.brand.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }

                if !exercise.equipment.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary.opacity(0.6))
                        Text(exercise.equipment)
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
        }
        .padding(12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
    }
}

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ExerciseGifThumbnail(exercise: exercise, size: 200)
                            .padding(.top, 8)

                        VStack(spacing: 16) {
                            infoRow(label: "Category", value: exercise.category.displayName)
                            infoRow(label: "Equipment", value: exercise.equipment.isEmpty ? "None" : exercise.equipment)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Muscle Groups")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                        Text(muscle)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.brand)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.brand.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brand)
                }
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
        .padding(14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
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
