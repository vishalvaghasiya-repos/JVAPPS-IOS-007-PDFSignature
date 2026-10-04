//
//  CheckerboardView.swift
//  PDFSignature
//

import SwiftUI

struct CheckerboardView: View {
    var squareSize: CGFloat = 10
    var lightColor: Color = Color(white: 0.94)
    var darkColor: Color = Color(white: 0.86)

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(isEven ? lightColor : darkColor))
                }
            }
        }
    }
}
