import SwiftUI
import WidgetKit

struct TimeScopesPulsePrescriptionsWidget: Widget {
    let kind: String = WidgetSharedConstants.pulsePrescriptionsWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseWidgetProvider()) { entry in
            PulsePrescriptionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Pulse Prescriptions")
        .description("Actionable prescriptions")
        .supportedFamilies([.systemMedium])
    }
}

#if DEBUG
#Preview("Pulse Prescriptions", as: .systemMedium) {
    TimeScopesPulsePrescriptionsWidget()
} timeline: {
    WidgetPreviewData.pulseEntry
}
#endif
