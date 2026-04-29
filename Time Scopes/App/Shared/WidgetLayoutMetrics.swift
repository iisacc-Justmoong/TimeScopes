import CoreGraphics
import Foundation

enum WidgetLayoutMetrics {
    static let weekBarLabelHeight: CGFloat = 12
    static let weekBarLabelSpacing: CGFloat = 4
    static let minimumWeekBarHeight: CGFloat = 6

    static func weekBarPlotHeight(containerHeight: CGFloat) -> CGFloat {
        max(0, containerHeight - weekBarLabelHeight - weekBarLabelSpacing)
    }

    static func weekBarHeight(containerHeight: CGFloat, intensity: Double) -> CGFloat {
        let plotHeight = weekBarPlotHeight(containerHeight: containerHeight)
        guard plotHeight > 0 else { return 0 }

        let clampedIntensity = min(1, max(0, intensity))
        let minimumHeight = min(minimumWeekBarHeight, plotHeight)
        return min(plotHeight, max(minimumHeight, plotHeight * CGFloat(clampedIntensity)))
    }
}
