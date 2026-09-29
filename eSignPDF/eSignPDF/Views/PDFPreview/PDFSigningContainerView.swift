//
//  PDFSigningContainerView.swift
//  eSignPDF
//

import SwiftUI

struct PDFSigningContainerView: View {
    let sourceURL: URL
    let onClose: () -> Void

    var body: some View {
        PDFSigningView(sourceURL: sourceURL, onClose: onClose)
    }
}
