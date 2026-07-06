import SwiftUI

struct ExercisePickerView: View {
    let onSelect: (Exercise) -> Void

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @Environment(\.dismiss) var dismiss

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
            .navigationTitle("Pick Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brand)
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
        }
    }

    // MARK: - Muscle Group Filter

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

    // MARK: - Exercise List

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
                            ExercisePickerRow(exercise: exercise) {
                                onSelect(exercise)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - Exercise Picker Row

struct ExercisePickerRow: View {
    let exercise: Exercise
    let onTap: () -> Void

    @State private var showDetail = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Animated GIF thumbnail
                ExerciseGifThumbnail(exercise: exercise, size: 68)

                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    // Muscle groups as pills
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

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(colors: [.brand, Color(red: 0, green: 0.9, blue: 0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(12)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip (legacy, kept for other views)

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
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
