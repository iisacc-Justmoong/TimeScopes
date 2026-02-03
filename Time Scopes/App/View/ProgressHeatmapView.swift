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
        let columns = [
            GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: cellSpacing)
        ]

        LazyVGrid(columns: columns, alignment: .leading, spacing: cellSpacing) {
            ForEach(0..<safeTotal, id: \.self) { index in
                HeatmapCell(
                    isFilled: index < safeFilled,
                    size: cellSize,
                    filledColor: filledColor,
                    emptyColor: emptyColor
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
