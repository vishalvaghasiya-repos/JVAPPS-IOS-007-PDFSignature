//
//  AppWebViewScreen.swift
//  eSignPDF
//

import SwiftUI
import WebKit
import AdsManagerKit

struct WebViewItem: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: Error?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.error = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.error = error
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.error = error
            }
        }
    }
}

struct AppWebViewScreen: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let title: String

    @State private var isLoading = true
    @State private var error: Error? = nil
    
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                        Text("Failed to load page")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    WebView(url: url, isLoading: $isLoading, error: $error)
                        .opacity(isLoading ? 0 : 1)
                        .overlay {
                            if isLoading {
                                ProgressView("Loading…")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            BannerAdView(
                adType: .ADAPTIVE,
                isLoaded: $bannerIsLoaded,
                height: $bannerHeight
            )
            .frame(height: bannerHeight)
        }
    }
}
