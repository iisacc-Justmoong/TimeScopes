import SwiftUI
import WidgetKit

struct TimeScopesPulseJournalWidget: Widget {
    let kind: String = WidgetSharedConstants.pulseJournalWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseWidgetProvider()) { entry in
            PulseJournalWidgetView(entry: entry)
        }
        .configurationDisplayName("Pulse Daily Journal")
        .description("Quick daily journal entry")
        .supportedFamilies([.systemSmall])
    }
}

#if DEBUG
#Preview("Pulse Journal", as: .systemSmall) {
    TimeScopesPulseJournalWidget()
} timeline: {
    WidgetPreviewData.pulseEntry
}
#endif
