import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = "ruggeroartini03@gmail.com"
    @State private var password = "testtest"
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            LiftLogLogoView(size: 72)
                                .padding(.top, 60)
                            Text("LiftLog")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Text("Your premium training companion")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.bottom, 48)

                        // Form
                        VStack(spacing: 14) {
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
                                contentType: .password
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                        // Buttons
                        VStack(spacing: 12) {
                            BrandButton(
                                title: "Log In",
                                isLoading: authViewModel.isLoading,
                                isDisabled: email.isEmpty || password.isEmpty
                            ) {
                                Task { await authViewModel.signIn(email: email, password: password) }
                            }

                            Button {
                                showRegister = true
                            } label: {
                                Text("Don't have an account? ")
                                    .foregroundColor(.textSecondary)
                                + Text("Sign Up")
                                    .foregroundColor(.brand)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
        .errorAlert(error: $authViewModel.error)
    }
}
