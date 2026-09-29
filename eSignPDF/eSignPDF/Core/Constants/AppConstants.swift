//
//  AppConstants.swift
//  eSignPDF
//

import Foundation

enum AppConstants {
    static let appDisplayName = "E-Sign PDF"

    /// Free-tier cap before upgrade (debug builds use a higher limit for testing).
    static var freeSignLimit: Int {
        #if DEBUG
        50
        #else
        10
        #endif
    }

    /// Must match the entitlement identifier in your RevenueCat dashboard.
    static let defaultRevenueCatEntitlementID = "premium"

    /// Must match **iCloud** capability container in Xcode (and SignFlow.entitlements).
    static let iCloudContainerIdentifier = "iCloud.com.jvapps.signflow"

    enum ProductID {
        static let weekly = "com.jvapps.signflow.weekly"
        static let monthly = "com.jvapps.signflow.monthly"
        static let yearly = "com.jvapps.signflow.yearly"
        static let all: [String] = [weekly, monthly, yearly]
    }

    enum URLs {
        static let appID = "6768590632"
        static let privacy = URL(string: "https://sites.google.com/view/jyotivaidya/privacy-policy")!
        static let terms = URL(string: "https://sites.google.com/view/jyotivaidya/terms-conditions")!
        static let support = URL(string: "mailto:jyotivaidya97@gmail.com")!
        static let appStoreReview = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
        static let feedback = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSf5eZQ8CLBR7ksoInHryrAEVmCkpnqED8HBicQQCAMYhIRIHw/viewform")!
    }
}
