import SwiftUI
import WidgetKit

struct TimeScopesMilestonesWidget: Widget {
    let kind: String = WidgetSharedConstants.milestonesWidgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: MilestonesWidgetConfigurationIntent.self, provider: MilestonesWidgetProvider()) { entry in
            TimeScopesMilestonesWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Milestones")
        .description("Upcoming milestones section")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if DEBUG
#Preview("Milestones Small", as: .systemSmall) {
    TimeScopesMilestonesWidget()
} timeline: {
    WidgetPreviewData.milestonesEntry(metric: .yearsUntilNextDecade)
}

#Preview("Milestones Medium", as: .systemMedium) {
    TimeScopesMilestonesWidget()
} timeline: {
    WidgetPreviewData.milestonesEntry(metric: .weekdaysRemaining)
}
#endif
