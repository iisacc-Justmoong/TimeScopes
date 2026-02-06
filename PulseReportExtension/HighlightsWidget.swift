import SwiftUI
import WidgetKit

struct TimeScopesHighlightsWidget: Widget {
    let kind: String = WidgetSharedConstants.highlightsWidgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HighlightsWidgetConfigurationIntent.self, provider: HighlightsWidgetProvider()) { entry in
            TimeScopesHighlightsWidgetView(entry: entry)
        }
        .configurationDisplayName("Annual Highlights")
        .description("Annual highlights section")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if DEBUG
#Preview("Highlights Small", as: .systemSmall) {
    TimeScopesHighlightsWidget()
} timeline: {
    WidgetPreviewData.highlightsEntry(metric: .nextChristmas)
}

#Preview("Highlights Medium", as: .systemMedium) {
    TimeScopesHighlightsWidget()
} timeline: {
    WidgetPreviewData.highlightsEntry(metric: .remainingMondays)
}
#endif
