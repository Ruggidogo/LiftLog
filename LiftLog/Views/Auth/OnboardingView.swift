import SwiftUI
import AVKit

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            videoName: "onboarding_1",
            title: "Track Every Rep",
            subtitle: "Log your sets, reps and weight in real time — never lose a PR again."
        ),
        OnboardingPage(
            videoName: "onboarding_2",
            title: "See Your Progress",
            subtitle: "Beautiful charts show exactly how your strength improves week after week."
        ),
        OnboardingPage(
            videoName: "onboarding_3",
            title: "Train With Your PT",
            subtitle: "Personal trainers can assign plans and monitor client performance remotely."
        ),
        OnboardingPage(
            videoName: "onboarding_4",
            title: "Stay Consistent",
            subtitle: "Smart reminders keep you on schedule. Build habits that last."
        )
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Full screen video tab view
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Overlay: logo top, content bottom
            VStack {
                // Logo in alto
                HStack {
                    LiftLogLogoView(size: 52)
                    Text("LiftLog")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)

                Spacer()

                // Testo + dots + bottoni in basso
                VStack(spacing: 0) {
                    // Gradient scuro da trasparente a nero
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)

                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text(pages[currentPage].title)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)

                            Text(pages[currentPage].subtitle)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }

                        // Page dots
                        HStack(spacing: 8) {
                            ForEach(0..<pages.count, id: \.self) { i in
                                Capsule()
                                    .fill(i == currentPage
                                          ? Color(red: 0.13, green: 0.75, blue: 0.43)
                                          : Color.white.opacity(0.35))
                                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                                    .animation(.spring(response: 0.3), value: currentPage)
                            }
                        }

                        // CTA
                        VStack(spacing: 12) {
                            Button {
                                if currentPage < pages.count - 1 {
                                    withAnimation { currentPage += 1 }
                                } else {
                                    showOnboarding = false
                                }
                            } label: {
                                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color(red: 0.13, green: 0.75, blue: 0.43))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            Button {
                                showOnboarding = false
                            } label: {
                                Text("I already have an account")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 44)
                    .background(Color.black.opacity(0.85))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingPage {
    let videoName: String
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            if let url = Bundle.main.url(forResource: page.videoName, withExtension: "mp4") {
                LoopingVideoPlayer(url: url)
                    .ignoresSafeArea()
            } else {
                // Fallback finché i video non sono aggiunti al bundle
                OnboardingFallbackView(videoName: page.videoName)
            }

            // Leggero vignette scuro sui bordi
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.3), .clear, .clear, .black.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }
}

// Video in loop senza controlli
struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingVideoView {
        let view = LoopingVideoView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingVideoView, context: Context) {}
}

final class LoopingVideoView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)

        self.player = player
        self.playerLayer = layer

        player.play()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loop),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    @objc private func loop() {
        player?.seek(to: .zero)
        player?.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
    }
}

// Fallback visivo mentre i video non sono nel bundle
struct OnboardingFallbackView: View {
    let videoName: String
    private let icons = ["figure.strengthtraining.traditional", "chart.line.uptrend.xyaxis", "person.2.fill", "bell.badge.fill"]
    private let index: Int

    init(videoName: String) {
        self.videoName = videoName
        let n = Int(videoName.last?.asciiValue ?? 49) - 48
        self.index = max(0, min(n - 1, 3))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.12, blue: 0.08),
                    Color(red: 0.02, green: 0.06, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: icons[index])
                .font(.system(size: 100, weight: .thin))
                .foregroundColor(.white.opacity(0.08))
        }
        .ignoresSafeArea()
    }
}

// Logo programmatico — L + L speculare su sfondo verde scuro
struct LiftLogLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(red: 0.07, green: 0.27, blue: 0.18))
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.09, green: 0.33, blue: 0.21).opacity(0.9), .clear],
                                center: .init(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: size * 0.65
                            )
                        )
                )
                .shadow(color: Color(red: 0.12, green: 0.55, blue: 0.33).opacity(0.45), radius: size * 0.18, y: size * 0.07)

            HStack(spacing: size * 0.04) {
                LLetterShape()
                    .fill(.white)
                    .frame(width: size * 0.30, height: size * 0.42)
                LLetterShape()
                    .fill(.white)
                    .frame(width: size * 0.30, height: size * 0.42)
                    .scaleEffect(x: -1, y: 1)
            }
        }
        .frame(width: size, height: size)
    }
}

struct LLetterShape: Shape {
    func path(in rect: CGRect) -> Path {
        let t = rect.width * 0.36
        var p = Path()
        p.addRect(CGRect(x: 0, y: 0, width: t, height: rect.height))
        p.addRect(CGRect(x: 0, y: rect.height - t, width: rect.width, height: t))
        return p
    }
}
