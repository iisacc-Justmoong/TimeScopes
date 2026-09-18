import SwiftUI
import WidgetKit

struct TimeScopesPulseTodayWidget: Widget {
    let kind: String = WidgetSharedConstants.pulseTodayWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseWidgetProvider()) { entry in
            PulseTodayStructureWidgetView(entry: entry)
        }
        .configurationDisplayName("Pulse Today Structure")
        .description("Today structure pulse chart")
        .supportedFamilies([.systemMedium])
    }
}

#if DEBUG
#Preview("Pulse Today", as: .systemMedium) {
    TimeScopesPulseTodayWidget()
} timeline: {
    WidgetPreviewData.pulseEntry
}
#endif
