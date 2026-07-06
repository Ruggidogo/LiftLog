import SwiftUI

struct WorkoutPlanListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showBuilder = false
    @State private var editingPlan: WorkoutPlan?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.plans.isEmpty {
                        ProgressView().tint(.brand)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.plans.isEmpty {
                        emptyState
                    } else {
                        plansList
                    }
                }
            }
            .navigationTitle("My Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingPlan = nil
                        showBuilder = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.brand)
                        }
                    }
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.loadPlans(for: userId)
                }
            }
            .sheet(isPresented: $showBuilder) {
                WorkoutPlanBuilderView(viewModel: viewModel, existingPlan: editingPlan)
            }
        }
        .errorAlert(error: $viewModel.error)
    }

    // MARK: - Plans List

    private var plansList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(viewModel.plans) { plan in
                    PlanCard(plan: plan) {
                        editingPlan = plan
                        showBuilder = true
                    } onDelete: {
                        Task { await viewModel.deletePlan(plan) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            PremiumIcon.blue(systemName: "list.bullet.clipboard.fill", size: 72)

            VStack(spacing: 8) {
                Text("No plans yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text("Build your first workout plan\nand start training smarter.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            BrandButton(title: "Create My First Plan") {
                showBuilder = true
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: WorkoutPlan
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var goalGradient: [Color] {
        switch plan.goal {
        case .strength:    return [Color(red: 0.13, green: 0.75, blue: 0.43), Color(red: 0, green: 0.9, blue: 0.55)]
        case .hypertrophy: return [Color(red: 0.4, green: 0.55, blue: 1.0), Color(red: 0.6, green: 0.8, blue: 1.0)]
        case .endurance:   return [Color(red: 1.0, green: 0.55, blue: 0.1), Color(red: 1.0, green: 0.85, blue: 0.2)]
        case .weightLoss:  return [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.7)]
        case .mixed:       return [Color(red: 0.7, green: 0.35, blue: 1.0), Color(red: 0.9, green: 0.6, blue: 1.0)]
        }
    }

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 0) {
                // Top: gradient accent bar
                LinearGradient(colors: goalGradient, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                HStack(alignment: .top, spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(colors: [goalGradient[0].opacity(0.2), goalGradient[0].opacity(0.07)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(goalGradient[0].opacity(0.35), lineWidth: 1)
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: plan.goal.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: goalGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        // Goal badge
                        Text(plan.goal.displayName.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: goalGradient, startPoint: .leading, endPoint: .trailing)
                            )
                            .tracking(1.0)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(goalGradient[0].opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Chevron + delete
                    VStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                // Footer: creation date
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary.opacity(0.6))
                    Text("Created \(plan.createdAt, style: .date)")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary.opacity(0.6))
                    Spacer()
                    Text("Edit plan →")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(goalGradient[0])
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .confirmationDialog("Delete this plan?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
