//
//  ProgressHeatmapView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct ProgressHeatmapView: View {
    let totalCells: Int
    let filledCells: Int
    var cellSize: CGFloat = 10
    var cellSpacing: CGFloat = 3
    var columnSpacing: CGFloat = 5
    var filledColor: Color = .accentColor
    var emptyColor: Color = Color.accentColor.opacity(0.2)

    var body: some View {
        let safeTotal = max(0, totalCells)
        let safeFilled = min(max(0, filledCells), safeTotal)
        let columnCount = safeTotal > 0 ? Int(ceil(Double(safeTotal) / 7.0)) : 0

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: columnSpacing) {
                ForEach(0..<columnCount, id: \.self) { column in
                    let startIndex = column * 7
                    let rowCount = min(7, safeTotal - startIndex)
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<rowCount, id: \.self) { row in
                            let index = startIndex + row
                            HeatmapCell(
                                isFilled: index < safeFilled,
                                size: cellSize,
                                filledColor: filledColor,
                                emptyColor: emptyColor
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct HeatmapCell: View {
    let isFilled: Bool
    let size: CGFloat
    let filledColor: Color
    let emptyColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isFilled ? filledColor : emptyColor)
            .frame(width: size, height: size)
    }
}

#Preview {
    ProgressHeatmapView(totalCells: 50, filledCells: 18)
        .padding()
        .glassScreen()
}
