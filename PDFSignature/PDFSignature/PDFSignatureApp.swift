//
//  PDFSignatureApp.swift
//  PDFSignature
//

import SwiftData
import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import AdsManagerKit
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      // Enable analytics collection explicitly (optional)
      Analytics.setAnalyticsCollectionEnabled(true)
    return true
  }
}

@main
struct PDFSignatureApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var router = AppRouter()
    
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasLaunched = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SignatureRecord.self,
            SignedDocumentRecord.self,
        ])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(router)
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        if !hasLaunched {
                            // Show Open Ad only when returning from background
                            hasLaunched = true
                            AdsManager.shared.tryToPresentSplashAd()
                        }
                    }
                    if scenePhase == .background {
                        hasLaunched = false
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
