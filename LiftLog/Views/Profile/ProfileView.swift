import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("appTheme") private var appTheme: String = "system"

    @State private var editedName: String = ""
    @State private var selectedTheme: AppTheme = .system
    @State private var selectedLanguage: AppLanguage = .en
    @State private var showSignOutConfirm = false
    @State private var notifEnabled = true
    @State private var reminderTime = "08:00"
    @State private var customMessage = ""

    var user: AppUser? { authViewModel.currentUser }

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                personalSection
                themeSection
                notificationSection
                subscriptionSection
                if user?.role == .pt {
                    ptSection
                }
                signOutSection
            }
            .navigationTitle(String(localized: "tab.profile"))
            .task {
                if let user {
                    editedName = user.fullName
                    selectedTheme = user.theme
                    selectedLanguage = user.language
                    await viewModel.loadNotificationSettings(for: user.id)
                    if let settings = viewModel.notificationSettings {
                        notifEnabled = settings.enabled
                        reminderTime = settings.reminderTime
                        customMessage = settings.customMessage
                    }
                }
            }
        }
        .errorAlert(error: $viewModel.error)
        .alert(String(localized: "profile.signout.title"), isPresented: $showSignOutConfirm) {
            Button(String(localized: "button.signout"), role: .destructive) {
                Task { await authViewModel.signOut() }
            }
            Button(String(localized: "button.cancel"), role: .cancel) {}
        }
    }

    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 80, height: 80)
                        Text(initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                    Text(user?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private var personalSection: some View {
        Section(String(localized: "profile.personal")) {
            HStack {
                Text(String(localized: "field.full_name"))
                TextField(String(localized: "field.full_name"), text: $editedName)
                    .multilineTextAlignment(.trailing)
                    .onSubmit { saveProfile() }
            }
            Picker(String(localized: "profile.language"), selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .onChange(of: selectedLanguage) { _, _ in saveProfile() }
        }
    }

    private var themeSection: some View {
        Section(String(localized: "profile.appearance")) {
            Picker(String(localized: "profile.theme"), selection: $selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTheme) { _, newVal in
                appTheme = newVal.rawValue
                saveProfile()
            }
        }
    }

    private var notificationSection: some View {
        Section(String(localized: "profile.notifications")) {
            Toggle(String(localized: "profile.notif_enabled"), isOn: $notifEnabled)
                .onChange(of: notifEnabled) { _, _ in saveNotifications() }

            if notifEnabled {
                HStack {
                    Text(String(localized: "profile.reminder_time"))
                    Spacer()
                    TextField("08:00", text: $reminderTime)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .frame(width: 80)
                        .onSubmit { saveNotifications() }
                }
                TextField(String(localized: "profile.custom_message"), text: $customMessage)
                    .onSubmit { saveNotifications() }
            }
        }
    }

    private var subscriptionSection: some View {
        Section(String(localized: "profile.subscription")) {
            HStack {
                Text(String(localized: "profile.status"))
                Spacer()
                Text(subscriptionLabel)
                    .foregroundColor(subscriptionColor)
                    .bold()
            }

            if user?.subscriptionStatus == .trial, let trialEnd = user?.trialEndDate {
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
                Text(String(localized: "profile.trial_days \(max(0, daysLeft))"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(String(localized: "profile.manage_subscription")) {
                StripeService.shared.openCustomerPortal()
            }
        }
    }

    private var ptSection: some View {
        Section {
            NavigationLink(String(localized: "profile.my_clients")) {
                ClientListView()
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(String(localized: "button.signout"), role: .destructive) {
                showSignOutConfirm = true
            }
        }
    }

    private var initials: String {
        let parts = (user?.fullName ?? "").components(separatedBy: " ")
        return parts.compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }

    private var subscriptionLabel: String {
        switch user?.subscriptionStatus {
        case .trial: return String(localized: "subscription.trial")
        case .active: return String(localized: "subscription.active")
        case .expired: return String(localized: "subscription.expired")
        default: return "-"
        }
    }

    private var subscriptionColor: Color {
        switch user?.subscriptionStatus {
        case .trial: return .orange
        case .active: return .green
        case .expired: return .red
        default: return .secondary
        }
    }

    private func saveProfile() {
        guard var updatedUser = user else { return }
        updatedUser.fullName = editedName
        updatedUser.theme = selectedTheme
        updatedUser.language = selectedLanguage
        Task {
            try? await viewModel.updateProfile(user: updatedUser)
            authViewModel.currentUser = updatedUser
        }
    }

    private func saveNotifications() {
        guard let userId = user?.id else { return }
        let settings = NotificationSettings(userId: userId, enabled: notifEnabled, reminderTime: reminderTime, customMessage: customMessage)
        Task { await viewModel.saveNotificationSettings(settings) }
    }
}
