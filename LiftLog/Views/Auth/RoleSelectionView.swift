import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedRole: UserRole?

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text(String(localized: "role.title"))
                    .font(.largeTitle.bold())
                Text(String(localized: "role.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)

            VStack(spacing: 16) {
                RoleCard(
                    role: .athlete,
                    icon: "figure.strengthtraining.traditional",
                    title: String(localized: "role.athlete"),
                    description: String(localized: "role.athlete.description"),
                    isSelected: selectedRole == .athlete
                ) { selectedRole = .athlete }

                RoleCard(
                    role: .pt,
                    icon: "person.2.fill",
                    title: String(localized: "role.pt"),
                    description: String(localized: "role.pt.description"),
                    isSelected: selectedRole == .pt
                ) { selectedRole = .pt }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                guard let role = selectedRole else { return }
                Task { await authViewModel.selectRole(role) }
            } label: {
                Group {
                    if authViewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(String(localized: "button.continue"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedRole == nil || authViewModel.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct RoleCard: View {
    let role: UserRole
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 56, height: 56)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
