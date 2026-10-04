//
//  LaunchView.swift
//  eSignPDF
//

import SwiftUI
import AdsManagerKit
import FirebaseRemoteConfig
import Network

struct LaunchView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    
    @State private var adDelegate = SplashAdDelegate()
    @State private var showMainScreen = false
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.09),
                    Color(red: 0.06, green: 0.11, blue: 0.12),
                    Color(red: 0.08, green: 0.14, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image("splash_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .opacity(contentOpacity)
                
                Spacer()
                
                bottomLoader
                    .padding(.bottom, 28)
                    .opacity(contentOpacity)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startAnimations()
            configureSetup()
        }
    }
    
    // MARK: - Loader
    
    private var bottomLoader: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Theme.primary)
            .scaleEffect(1.1)
            .padding(.top, 4)
    }
    
    // MARK: - Environment
    
    private var remoteConfigKey: String {
        #if DEBUG || TESTING
        return "appConfigurationTest"
        #else
        return "appConfiguration"
        #endif
    }
    
    private var remoteConfigFetchInterval: TimeInterval {
        #if DEBUG
        return 0
        #elseif TESTING
        return 300
        #else
        return 3600
        #endif
    }
    
    // MARK: - Setup
    
    private func configureSetup() {
        
        adDelegate.onComplete = {
            Task { @MainActor in
                startMainScreen()
            }
        }
        
        guard NetworkMonitor.isConnected else {
            initializeWithoutRemoteConfig()
            return
        }
        
        fetchRemoteConfiguration()
    }
    
    // MARK: - Remote Configuration
    
    private func fetchRemoteConfiguration() {
        
        let remoteConfig = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = remoteConfigFetchInterval
        remoteConfig.configSettings = settings
        
        remoteConfig.fetch(withExpirationDuration: remoteConfigFetchInterval) { status, _ in
            
            guard status == .success else {
                DispatchQueue.main.async {
                    self.initializeWithoutRemoteConfig()
                }
                return
            }
            
            remoteConfig.activate { _, _ in
                DispatchQueue.main.async {
                    self.applyRemoteConfiguration(remoteConfig)
                }
            }
        }
    }
    
    // MARK: - Configuration
    
    private func applyRemoteConfiguration(_ remoteConfig: RemoteConfig) {
        
        let jsonString = remoteConfig.configValue(forKey: remoteConfigKey).stringValue
        
        guard let data = jsonString.data(using: .utf8), !data.isEmpty else {
            initializeWithoutRemoteConfig()
            return
        }
        
        do {
            let configuration = try JSONDecoder().decode(
                AppConfiguration.self,
                from: data
            )
            
            initializeAds(configuration: configuration)
        } catch {
            initializeWithoutRemoteConfig()
        }
    }
    
    // MARK: - Ads Initialization
    
    private func initializeAds(configuration: AppConfiguration) {
        
        AdsManager.initialize(with: configuration) {
            let delay = max(0, AdsConfig.splashDelaySeconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                presentSplashAd()
            }
        }
    }
    
    private func initializeWithoutRemoteConfig() {
        
        AdsManager.initialize()
        
        DispatchQueue.main.async {
            startMainScreen()
        }
    }
    
    // MARK: - Splash
    
    private func presentSplashAd() {
        
        DispatchQueue.main.async {
            
            AdsManager.shared.tryToPresentSplashAd(
                delegate: adDelegate
            )
        }
    }
    
    // MARK: - Main Screen / Navigation
    
    @MainActor
    private func startMainScreen() {
        
        guard !showMainScreen else {
            return
        }
        
        showMainScreen = true
        
        // Handle next screen transition using switch
        switch appState.nextScreenAfterLaunch {
        case .onboarding:
            withAnimation(.easeInOut(duration: 0.45)) {
                appState.currentScreen = .onboarding
            }
        case .welcome:
            withAnimation(.easeInOut(duration: 0.45)) {
                appState.currentScreen = .welcome
            }
        case .mainTabBar:
            router.popToRoot(on: .home)
            withAnimation(.easeInOut(duration: 0.45)) {
                appState.currentScreen = .mainTabBar
            }
        }
        
        appState.launchFinished = true
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(
            .easeOut(duration: 0.9)
            .delay(0.15)
        ) {
            contentOpacity = 1
        }
    }
}

// MARK: - Network Monitor

private enum NetworkMonitor {
    
    static var isConnected: Bool {
        
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectionMonitor")
        let semaphore = DispatchSemaphore(value: 0)
        
        var connected = false
        
        monitor.pathUpdateHandler = { path in
            connected = path.status == .satisfied
            semaphore.signal()
        }
        
        monitor.start(queue: queue)
        
        _ = semaphore.wait(timeout: .now() + 1)
        
        monitor.cancel()
        
        return connected
    }
}

#Preview {
    LaunchView()
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}
