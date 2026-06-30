import SwiftUI

struct ClientListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var newClientEmail = ""
    @State private var error: AppError?

    var body: some View {
        Group {
            if viewModel.clients.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                List {
                    ForEach(viewModel.clients) { client in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(client.fullName.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.fullName)
                                    .font(.subheadline.bold())
                                Text(client.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let ptId = authViewModel.currentUser?.id {
                                    Task { await viewModel.removeClient(ptId: ptId, clientId: client.id) }
                                }
                            } label: {
                                Label(String(localized: "button.remove"), systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "profile.my_clients"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showAddClient = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .alert(String(localized: "client.add"), isPresented: $viewModel.showAddClient) {
            TextField(String(localized: "field.email"), text: $newClientEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Button(String(localized: "button.add")) {
                addClient()
            }
            Button(String(localized: "button.cancel"), role: .cancel) {
                newClientEmail = ""
            }
        }
        .task {
            if let ptId = authViewModel.currentUser?.id {
                await viewModel.loadClients(for: ptId)
            }
        }
        .errorAlert(error: $viewModel.error)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text(String(localized: "client.empty.title"))
                .font(.title3.bold())
            Text(String(localized: "client.empty.subtitle"))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                viewModel.showAddClient = true
            } label: {
                Label(String(localized: "client.add"), systemImage: "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    private func addClient() {
        guard !newClientEmail.isEmpty,
              let ptId = authViewModel.currentUser?.id else { return }
        Task {
            do {
                try await viewModel.addClient(ptId: ptId, email: newClientEmail)
                newClientEmail = ""
            } catch {
                viewModel.error = .validation(error.localizedDescription)
            }
        }
    }
}
