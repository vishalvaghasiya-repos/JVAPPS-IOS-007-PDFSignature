//
//  SignatureBackgroundRemover.swift
//  PDFSignature
//

import CoreGraphics
import Foundation
import UIKit

public enum SignatureBackgroundRemover {

    /// Processes an input image of a signature, removing the paper background and isolating the ink.
    /// - Parameters:
    ///   - image: Source UIImage
    ///   - threshold: Luminance threshold (0.2 to 0.95). Pixels brighter than this become transparent.
    ///   - smoothness: Transition softness for smooth edges (0.02 to 0.2).
    ///   - inkColor: Optional tint color for the signature (e.g. pure black or navy). If nil, original ink color is preserved.
    ///   - invert: Inverts brightness (useful if signature was white on dark background).
    ///   - autoCrop: If true, crops empty transparent margins around the signature.
    /// - Returns: A transparent UIImage containing only the signature strokes.
    public static func removeBackground(
        from image: UIImage,
        threshold: CGFloat = 0.78,
        smoothness: CGFloat = 0.08,
        inkColor: UIColor? = nil,
        invert: Bool = false,
        autoCrop: Bool = true
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0
        var hasVisibleInk = false

        var targetR: UInt8 = 0
        var targetG: UInt8 = 0
        var targetB: UInt8 = 0

        if let inkColor {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            inkColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            targetR = UInt8(max(0, min(255, r * 255)))
            targetG = UInt8(max(0, min(255, g * 255)))
            targetB = UInt8(max(0, min(255, b * 255)))
        }

        let thresh = Float(threshold)
        let soft = max(Float(smoothness), 0.01)

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let offset = rowOffset + x * bytesPerPixel
                let r = Float(rawData[offset]) / 255.0
                let g = Float(rawData[offset + 1]) / 255.0
                let b = Float(rawData[offset + 2]) / 255.0
                let originalAlpha = Float(rawData[offset + 3]) / 255.0

                // Relative luminance (Rec. 709)
                var luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
                if invert {
                    luminance = 1.0 - luminance
                }

                // If luminance is above threshold, paper is transparent
                let lowerBound = max(0.0, thresh - soft)
                let alphaMultiplier: Float
                if luminance >= thresh {
                    alphaMultiplier = 0.0
                } else if luminance <= lowerBound {
                    alphaMultiplier = 1.0
                } else {
                    // Smooth linear falloff
                    alphaMultiplier = (thresh - luminance) / (thresh - lowerBound)
                }

                let finalAlpha = originalAlpha * alphaMultiplier

                if finalAlpha > 0.05 {
                    hasVisibleInk = true
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }

                if let _ = inkColor {
                    // Pre-multiply alpha for target ink
                    rawData[offset] = UInt8(Float(targetR) * finalAlpha)
                    rawData[offset + 1] = UInt8(Float(targetG) * finalAlpha)
                    rawData[offset + 2] = UInt8(Float(targetB) * finalAlpha)
                } else {
                    // Preserve original ink colors with new alpha
                    rawData[offset] = UInt8(r * 255.0 * finalAlpha)
                    rawData[offset + 1] = UInt8(g * 255.0 * finalAlpha)
                    rawData[offset + 2] = UInt8(b * 255.0 * finalAlpha)
                }
                rawData[offset + 3] = UInt8(finalAlpha * 255.0)
            }
        }

        guard let outputCgImage = context.makeImage() else { return nil }
        var resultImage = UIImage(cgImage: outputCgImage, scale: image.scale, orientation: image.imageOrientation)

        // Auto-crop to content bounding box with a small margin
        if autoCrop && hasVisibleInk && minX < maxX && minY < maxY {
            let padding = 16
            let cropX = max(0, minX - padding)
            let cropY = max(0, minY - padding)
            let cropWidth = min(width - cropX, (maxX - minX) + padding * 2)
            let cropHeight = min(height - cropY, (maxY - minY) + padding * 2)

            let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            if let cropped = outputCgImage.cropping(to: cropRect) {
                resultImage = UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
            }
        }

        return resultImage
    }
}
