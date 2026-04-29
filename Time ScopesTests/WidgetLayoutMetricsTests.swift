import XCTest
@testable import Time_Scopes

final class WidgetLayoutMetricsTests: XCTestCase {
    func testWeekBarHeightReservesLabelAreaInsideChartFrame() {
        let containerHeight: CGFloat = 90
        let plotHeight = WidgetLayoutMetrics.weekBarPlotHeight(containerHeight: containerHeight)

        XCTAssertEqual(
            plotHeight
                + WidgetLayoutMetrics.weekBarLabelSpacing
                + WidgetLayoutMetrics.weekBarLabelHeight,
            containerHeight
        )
        XCTAssertLessThanOrEqual(
            WidgetLayoutMetrics.weekBarHeight(containerHeight: containerHeight, intensity: 1),
            plotHeight
        )
    }

    func testWeekBarHeightClampsIntensityToPlotHeight() {
        let containerHeight: CGFloat = 90
        let plotHeight = WidgetLayoutMetrics.weekBarPlotHeight(containerHeight: containerHeight)

        XCTAssertEqual(
            WidgetLayoutMetrics.weekBarHeight(containerHeight: containerHeight, intensity: 2),
            plotHeight
        )
        XCTAssertEqual(
            WidgetLayoutMetrics.weekBarHeight(containerHeight: containerHeight, intensity: -1),
            WidgetLayoutMetrics.minimumWeekBarHeight
        )
    }
}
