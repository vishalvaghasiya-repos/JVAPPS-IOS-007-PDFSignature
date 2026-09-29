//
//  LaunchView.swift
//  eSignPDF
//

import SwiftUI
import AdsManagerKit
import FirebaseRemoteConfigInternal
import Network

struct LaunchView: View {
    let onFinished: () -> Void
    
    @State private var logoScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var loadingPhase: CGFloat = 0
    @State private var shimmerX: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.09),
                    Color(red: 0.06, green: 0.11, blue: 0.12),
                    Color(red: 0.08, green: 0.14, blue: 0.15),
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
            withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                contentOpacity = 1
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                loadingPhase = 1
            }
            fetchFromRemoteConfig {
                DispatchQueue.main.async {
                    AdsManager.configure {
                        DispatchQueue.main.async {
                            onFinished()
                        }
                    }
                }
            }
        }
    }
    
    private var bottomLoader: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Theme.primary)
            .scaleEffect(1.1)
            .padding(.top, 4)
    }
}

#Preview {
    LaunchView {
        print("Launch Finished")
    }
}

private func fetchFromRemoteConfig(_ completion: @Sendable @escaping () -> Void) {
    if !checkInternet() {
        completion()
        return
    }
    
    let remoteConfig = RemoteConfig.remoteConfig()
    let settings = RemoteConfigSettings()
    #if DEBUG
    settings.minimumFetchInterval = 0
    #else
    settings.minimumFetchInterval = 3600
    #endif
    remoteConfig.configSettings = settings
    
    let expirationDuration = 0
    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
        guard status == .success else {
            completion()
            return
        }
        remoteConfig.activate { (success, error) in
            let config = RemoteConfig.remoteConfig()
            
            var isProduction = true
            #if DEBUG
            isProduction = false
            #endif
            
            let openAdEnabled = config.configValue(forKey: "openAdEnabled").boolValue
            let bannerAdEnabled = config.configValue(forKey: "bannerAdEnabled").boolValue
            let interstitialAdEnabled = config.configValue(forKey: "interstitialAdEnabled").boolValue
            let nativeAdEnabled = config.configValue(forKey: "nativeAdEnabled").boolValue
            let openAdUnitId = config.configValue(forKey: "openAdUnitId").stringValue
            let bannerAdUnitId = config.configValue(forKey: "bannerAdUnitId").stringValue
            let interstitialAdUnitId = config.configValue(forKey: "interstitialAdUnitId").stringValue
            let nativeAdUnitId = config.configValue(forKey: "nativeAdUnitId").stringValue
            let interstitialAdShowCount = Int(truncating: config.configValue(forKey: "interstitialAdShowCount").numberValue)
            let maxInterstitialAdsPerSession = Int(truncating: config.configValue(forKey: "maxInterstitialAdsPerSession").numberValue)
            let bannerAdErrorCount = Int(truncating: config.configValue(forKey: "bannerAdErrorCount").numberValue)
            let interstitialAdErrorCount = Int(truncating: config.configValue(forKey: "interstitialAdErrorCount").numberValue)
            let nativeAdErrorCount = Int(truncating: config.configValue(forKey: "nativeAdErrorCount").numberValue)
            
            DispatchQueue.main.async {
                AdsManager.configureAds(
                    isProduction: isProduction,
                    openAdEnabled: openAdEnabled,
                    bannerAdEnabled: bannerAdEnabled,
                    interstitialAdEnabled: interstitialAdEnabled,
                    nativeAdEnabled: nativeAdEnabled,
                    openAdUnitId: openAdUnitId,
                    bannerAdUnitId: bannerAdUnitId,
                    interstitialAdUnitId: interstitialAdUnitId,
                    nativeAdUnitId: nativeAdUnitId,
                    interstitialAdShowCount: interstitialAdShowCount,
                    maxInterstitialAdsPerSession: maxInterstitialAdsPerSession,
                    bannerAdErrorCount: bannerAdErrorCount,
                    interstitialAdErrorCount: interstitialAdErrorCount,
                    nativeAdErrorCount: nativeAdErrorCount
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    completion()
                })
            }
        }
    }
}

private func checkInternet() -> Bool {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    var isConnected = false
    let semaphore = DispatchSemaphore(value: 0)
    
    monitor.pathUpdateHandler = { path in
        isConnected = (path.status == .satisfied)
        semaphore.signal()
    }
    
    monitor.start(queue: queue)
    _ = semaphore.wait(timeout: .now() + 1)
    monitor.cancel()
    return isConnected
}
