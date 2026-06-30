import SwiftUI

struct ExercisePickerView: View {
    let onSelect: (Exercise) -> Void

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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

                List(viewModel.filtered) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        ExerciseListRow(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            .searchable(text: $viewModel.searchText, prompt: String(localized: "exercise.search"))
            .navigationTitle(String(localized: "exercise.pick"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
        }
    }
}
