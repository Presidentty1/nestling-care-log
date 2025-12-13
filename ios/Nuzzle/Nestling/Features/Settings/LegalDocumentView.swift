import SwiftUI
import WebKit

struct LegalDocumentView: View {
    enum DocumentType {
        case privacyPolicy
        case termsOfUse

        var title: String {
            switch self {
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfUse: return "Terms of Use"
            }
        }

        var fileName: String {
            switch self {
            case .privacyPolicy: return "privacy_policy"
            case .termsOfUse: return "terms_of_use"
            }
        }
    }

    let documentType: DocumentType
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                if let htmlContent = loadHTMLContent() {
                    WebView(htmlContent: htmlContent)
                } else {
                    // Trigger error alert on appear
                    Color.clear.onAppear {
                        showError = true
                    }
                }
            }
            .navigationTitle(documentType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("Document Unavailable", isPresented: $showError) {
            Button("OK") { dismiss() }
        } message: {
            Text("This legal document could not be loaded. Please contact support.")
        }
    }

    private func loadHTMLContent() -> String? {
        guard let resourceURL = Bundle.main.url(forResource: documentType.fileName, withExtension: "html") else {
            return nil
        }

        do {
            return try String(contentsOf: resourceURL, encoding: .utf8)
        } catch {
            print("Error loading HTML content: \(error)")
            return nil
        }
    }
}

// MARK: - WebView Wrapper
struct WebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}