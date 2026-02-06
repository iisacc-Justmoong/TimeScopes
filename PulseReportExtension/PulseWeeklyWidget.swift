import SwiftUI
import WidgetKit

struct TimeScopesPulseWeeklyWidget: Widget {
    let kind: String = WidgetSharedConstants.pulseWeeklyWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseWidgetProvider()) { entry in
            PulseWeeklyRhythmWidgetView(entry: entry)
        }
        .configurationDisplayName("Pulse Weekly Rhythm")
        .description("Weekly rhythm pulse chart")
        .supportedFamilies([.systemMedium])
    }
}

#if DEBUG
#Preview("Pulse Weekly", as: .systemMedium) {
    TimeScopesPulseWeeklyWidget()
} timeline: {
    WidgetPreviewData.pulseEntry
}
#endif
