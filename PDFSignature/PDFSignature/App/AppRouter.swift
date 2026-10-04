//
//  AppRouter.swift
//  PDFSignature
//

import Combine
import Foundation
import SwiftUI
import AdsManagerKit

enum AppRoute: Hashable {
    case signatureLibrary
    case newSignature
    case pdfSigning(URL)
    case pdfPreview(SignedDocumentModel)
    case webView(url: URL, title: String)
    case languageSelection
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var homePath: [AppRoute] = []
    @Published var historyPath: [AppRoute] = []
    @Published var settingsPath: [AppRoute] = []
    
    func push(_ route: AppRoute, on tab: AppState.MainTab) {
        AdsManager.shared.showInterstitialIfAvailable()
        switch tab {
        case .home:
            homePath.append(route)
        case .history:
            historyPath.append(route)
        case .settings:
            settingsPath.append(route)
        }
    }
    
    func pop(on tab: AppState.MainTab) {
        switch tab {
        case .home:
            if !homePath.isEmpty { homePath.removeLast() }
        case .history:
            if !historyPath.isEmpty { historyPath.removeLast() }
        case .settings:
            if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }
    
    func popToRoot(on tab: AppState.MainTab) {
        switch tab {
        case .home:
            homePath.removeAll()
        case .history:
            historyPath.removeAll()
        case .settings:
            settingsPath.removeAll()
        }
    }
}
