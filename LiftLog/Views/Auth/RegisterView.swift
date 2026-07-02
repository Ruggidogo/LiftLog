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
        ZStack {
            Color.brandDeep.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("\(Constants.Trial.durationDays) days free — no credit card needed")
                            .font(.subheadline)
                            .foregroundColor(.brand)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 12) {
                        BrandTextField(
                            placeholder: "Full Name",
                            text: $fullName,
                            contentType: .name
                        )
                        BrandTextField(
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            contentType: .emailAddress
                        )
                        BrandTextField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            contentType: .newPassword
                        )
                        BrandTextField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            isSecure: true,
                            contentType: .newPassword
                        )
                    }

                    if let err = validationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(err)
                        }
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.85))
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    BrandButton(
                        title: "Create Account",
                        isLoading: authViewModel.isLoading,
                        isDisabled: fullName.isEmpty || email.isEmpty || password.isEmpty
                    ) {
                        guard validate() else { return }
                        Task { await authViewModel.signUp(email: email, password: password, fullName: fullName) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .errorAlert(error: $authViewModel.error)
    }

    private func validate() -> Bool {
        validationError = nil
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError = "Please enter your name"
            return false
        }
        if !email.contains("@") {
            validationError = "Enter a valid email address"
            return false
        }
        if password.count < 6 {
            validationError = "Password must be at least 6 characters"
            return false
        }
        if password != confirmPassword {
            validationError = "Passwords don't match"
            return false
        }
        return true
    }
}
