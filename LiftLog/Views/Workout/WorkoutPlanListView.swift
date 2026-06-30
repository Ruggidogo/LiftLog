import SwiftUI

struct WorkoutPlanListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showBuilder = false
    @State private var editingPlan: WorkoutPlan?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.plans.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.plans.isEmpty {
                    emptyState
                } else {
                    plansList
                }
            }
            .navigationTitle(String(localized: "plans.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingPlan = nil
                        showBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.loadPlans(for: userId)
                }
            }
            .sheet(isPresented: $showBuilder) {
                WorkoutPlanBuilderView(
                    viewModel: viewModel,
                    existingPlan: editingPlan
                )
            }
        }
        .errorAlert(error: $viewModel.error)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text(String(localized: "plans.empty.title"))
                .font(.title3.bold())
            Text(String(localized: "plans.empty.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showBuilder = true
            } label: {
                Text(String(localized: "plans.create_first"))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    private var plansList: some View {
        List {
            ForEach(viewModel.plans) { plan in
                PlanRowView(plan: plan) {
                    editingPlan = plan
                    showBuilder = true
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.deletePlan(plan) }
                    } label: {
                        Label(String(localized: "button.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct PlanRowView: View {
    let plan: WorkoutPlan
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 14) {
                Image(systemName: plan.goal.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(plan.goal.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
