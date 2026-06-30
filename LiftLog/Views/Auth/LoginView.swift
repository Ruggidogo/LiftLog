import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.accentColor)
                        Text("LiftLog")
                            .font(.largeTitle.bold())
                        Text(String(localized: "login.subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 16) {
                        TextField(String(localized: "field.email"), text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)

                        SecureField(String(localized: "field.password"), text: $password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await authViewModel.signIn(email: email, password: password) }
                        } label: {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(String(localized: "button.login"))
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                        Button {
                            // Google Sign In — requires GoogleSignIn SDK integration
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text(String(localized: "button.signin_google"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        showRegister = true
                    } label: {
                        Text(String(localized: "login.no_account"))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
        .errorAlert(error: $authViewModel.error)
    }
}
