import SwiftUI
import WebKit

/// Renders an animated GIF URL inside a transparent WKWebView.
struct GifView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.backgroundColor = .clear
        web.isUserInteractionEnabled = false
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { background: transparent; display:flex; align-items:center; justify-content:center; width:100%; height:100%; }
        img { width:100%; height:100%; object-fit:cover; }
        </style>
        </head>
        <body><img src="\(url.absoluteString)"></body>
        </html>
        """
        web.loadHTMLString(html, baseURL: nil)
    }
}

/// Square GIF thumbnail with rounded corners and dark background.
struct ExerciseGifThumbnail: View {
    let exercise: Exercise
    var size: CGFloat = 64

    @State private var gifUrl: URL? = nil
    @State private var loaded = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.20)
                .fill(Color.surfaceHigh)

            if let url = gifUrl {
                GifView(url: url)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.20))
                    .opacity(loaded ? 1 : 0)
                    .onAppear { withAnimation(.easeIn(duration: 0.3)) { loaded = true } }
            } else {
                Image(systemName: exercise.category.icon)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.brand, Color(red: 0, green: 0.9, blue: 0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
        }
        .frame(width: size, height: size)
        .task {
            gifUrl = ExerciseGifMapper.url(for: exercise.name)
        }
    }
}
