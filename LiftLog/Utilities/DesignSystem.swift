import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let brand       = Color(red: 0.13, green: 0.75, blue: 0.43)  // verde primario
    static let brandDark   = Color(red: 0.07, green: 0.27, blue: 0.18)  // verde scuro sfondo
    static let brandDeep   = Color(red: 0.04, green: 0.14, blue: 0.09)  // verde quasi nero
    static let brandMid    = Color(red: 0.09, green: 0.40, blue: 0.24)  // verde medio
    static let surface     = Color(red: 0.10, green: 0.12, blue: 0.11)  // card surface
    static let surfaceHigh = Color(red: 0.14, green: 0.17, blue: 0.15)  // card elevata
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let divider     = Color.white.opacity(0.08)
}

// MARK: - Premium TextField
struct BrandTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    @State private var isVisible = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure && !isVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                }
            }
            .textContentType(contentType)
            .focused($focused)
            .foregroundColor(.textPrimary)
            .font(.body)
            .tint(.brand)

            if isSecure {
                Button { isVisible.toggle() } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surfaceHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(focused ? Color.brand.opacity(0.7) : Color.divider, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused)
    }
}

// MARK: - Primary Button
struct BrandButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: BrandButtonStyle = .primary
    let action: () -> Void

    enum BrandButtonStyle { case primary, secondary, ghost }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? .black : .brand)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(style == .primary ? .black : .brand)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.45 : 1)
    }

    @ViewBuilder var background: some View {
        switch style {
        case .primary:
            Color.brand
        case .secondary:
            Color.brand.opacity(0.12)
        case .ghost:
            Color.clear
        }
    }
}

// MARK: - Card
struct BrandCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.divider, lineWidth: 1)
            )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
            Spacer()
            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.subheadline)
                        .foregroundColor(.brand)
                }
            }
        }
    }
}
