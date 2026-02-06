import SwiftUI
import WidgetKit

struct TimeScopesProfileWidget: Widget {
    let kind: String = WidgetSharedConstants.profileWidgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ProfileWidgetConfigurationIntent.self, provider: ProfileWidgetProvider()) { entry in
            TimeScopesProfileWidgetView(entry: entry)
        }
        .configurationDisplayName("Profile")
        .description("Profile section")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if DEBUG
#Preview("Profile Small", as: .systemSmall) {
    TimeScopesProfileWidget()
} timeline: {
    WidgetPreviewData.profileEntry(metric: .age)
}

#Preview("Profile Medium", as: .systemMedium) {
    TimeScopesProfileWidget()
} timeline: {
    WidgetPreviewData.profileEntry(metric: .monthsLeft)
}
#endif
