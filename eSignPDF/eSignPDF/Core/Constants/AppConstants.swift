//
//  AppConstants.swift
//  eSignPDF
//

import Foundation

enum AppConstants {
    static let appDisplayName = "PDF Signature"

    /// Must match **iCloud** capability container in Xcode (and SignFlow.entitlements).
    static let iCloudContainerIdentifier = "iCloud.com.jvapps.signflow"

    enum URLs {
        static let appID = "6768590632"
        static let privacy = URL(string: "https://sites.google.com/view/jyotivaidya/privacy-policy")!
        static let terms = URL(string: "https://sites.google.com/view/jyotivaidya/terms-conditions")!
        static let support = URL(string: "mailto:jyotivaidya97@gmail.com")!
        static let appStoreReview = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
        static let feedback = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSf5eZQ8CLBR7ksoInHryrAEVmCkpnqED8HBicQQCAMYhIRIHw/viewform")!
    }
}
