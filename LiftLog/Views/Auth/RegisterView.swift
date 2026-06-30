import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var validationError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(String(localized: "register.title"))
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                VStack(spacing: 14) {
                    TextField(String(localized: "field.full_name"), text: $fullName)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)

                    TextField(String(localized: "field.email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    SecureField(String(localized: "field.password"), text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    SecureField(String(localized: "field.confirm_password"), text: $confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                }

                if let validationError {
                    Text(validationError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    guard validate() else { return }
                    Task { await authViewModel.signUp(email: email, password: password, fullName: fullName) }
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(String(localized: "button.register"))
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(authViewModel.isLoading)

                Text(String(localized: "register.trial_note", defaultValue: "You get \(Constants.Trial.durationDays) days free trial."))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle(String(localized: "register.title"))
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(error: $authViewModel.error)
    }

    private func validate() -> Bool {
        validationError = nil
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError = String(localized: "validation.name_required")
            return false
        }
        if !email.contains("@") {
            validationError = String(localized: "validation.email_invalid")
            return false
        }
        if password.count < 6 {
            validationError = String(localized: "validation.password_short")
            return false
        }
        if password != confirmPassword {
            validationError = String(localized: "validation.password_mismatch")
            return false
        }
        return true
    }
}
