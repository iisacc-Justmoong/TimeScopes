import SwiftUI
import WidgetKit

struct TimeScopesElapsedWidget: Widget {
    let kind: String = WidgetSharedConstants.elapsedWidgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ElapsedWidgetConfigurationIntent.self, provider: ElapsedWidgetProvider()) { entry in
            TimeScopesElapsedWidgetView(entry: entry)
        }
        .configurationDisplayName("Elapsed Time")
        .description("Elapsed time section")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if DEBUG
#Preview("Elapsed Small", as: .systemSmall) {
    TimeScopesElapsedWidget()
} timeline: {
    WidgetPreviewData.elapsedEntry(metric: .days)
}

#Preview("Elapsed Medium", as: .systemMedium) {
    TimeScopesElapsedWidget()
} timeline: {
    WidgetPreviewData.elapsedEntry(metric: .hours)
}
#endif
