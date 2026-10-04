//
//  OnboardingModel.swift
//  PDFSignature
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onboarding1",
            title: "Sign PDF Documents Easily",
            subtitle: "Upload and sign your important PDF files anytime, anywhere."
        ),
        OnboardingPage(
            imageName: "onboarding2",
            title: "Manage Your Signatures",
            subtitle: "Create, save, edit, and reuse your signatures instantly."
        ),
        OnboardingPage(
            imageName: "onboarding3",
            title: "Export & Share Securely",
            subtitle: "Preview, download, and share signed documents securely."
        ),
    ]
}
