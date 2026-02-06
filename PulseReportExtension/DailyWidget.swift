import SwiftUI
import WidgetKit

struct TimeScopesDailyWidget: Widget {
    let kind: String = WidgetSharedConstants.dailyWidgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: DailyWidgetConfigurationIntent.self, provider: DailyWidgetProvider()) { entry in
            TimeScopesDailyWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Summary")
        .description("Daily summary section")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if DEBUG
#Preview("Daily Small", as: .systemSmall) {
    TimeScopesDailyWidget()
} timeline: {
    WidgetPreviewData.dailyEntry(metric: .timeLeft)
}

#Preview("Daily Medium", as: .systemMedium) {
    TimeScopesDailyWidget()
} timeline: {
    WidgetPreviewData.dailyEntry(metric: .allocatedTime)
}
#endif
