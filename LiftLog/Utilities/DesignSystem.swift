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

// MARK: - Premium Icon

/// Reusable premium icon: gradient SF Symbol on a glowing rounded-square background.
struct PremiumIcon: View {
    let systemName: String
    var size: CGFloat = 48
    var colors: [Color] = [.brand, Color(red: 0.0, green: 0.9, blue: 0.6)]
    var glowOpacity: Double = 0.25

    private var iconSize: CGFloat { size * 0.42 }
    private var cornerRadius: CGFloat { size * 0.30 }

    var body: some View {
        ZStack {
            // Glow layer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(colors.first ?? .brand)
                .blur(radius: size * 0.28)
                .opacity(glowOpacity)
                .frame(width: size, height: size)

            // Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [colors.first!.opacity(0.22), colors.first!.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [colors.first!.opacity(0.4), colors.first!.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(width: size, height: size)

            // Gradient icon
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

// MARK: - Icon color presets
extension PremiumIcon {
    static func green(systemName: String, size: CGFloat = 48) -> PremiumIcon {
        PremiumIcon(systemName: systemName, size: size,
                    colors: [.brand, Color(red: 0.0, green: 0.9, blue: 0.55)])
    }
    static func flame(systemName: String, size: CGFloat = 48) -> PremiumIcon {
        PremiumIcon(systemName: systemName, size: size,
                    colors: [Color(red: 1.0, green: 0.55, blue: 0.1), Color(red: 1.0, green: 0.85, blue: 0.2)],
                    glowOpacity: 0.3)
    }
    static func blue(systemName: String, size: CGFloat = 48) -> PremiumIcon {
        PremiumIcon(systemName: systemName, size: size,
                    colors: [Color(red: 0.35, green: 0.55, blue: 1.0), Color(red: 0.6, green: 0.8, blue: 1.0)])
    }
    static func purple(systemName: String, size: CGFloat = 48) -> PremiumIcon {
        PremiumIcon(systemName: systemName, size: size,
                    colors: [Color(red: 0.7, green: 0.35, blue: 1.0), Color(red: 0.9, green: 0.6, blue: 1.0)],
                    glowOpacity: 0.28)
    }
    static func rose(systemName: String, size: CGFloat = 48) -> PremiumIcon {
        PremiumIcon(systemName: systemName, size: size,
                    colors: [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.7)],
                    glowOpacity: 0.25)
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
