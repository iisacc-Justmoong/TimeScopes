import SwiftUI
import WidgetKit

@main
struct TimeScopesWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeScopesProfileWidget()
        TimeScopesElapsedWidget()
        TimeScopesMilestonesWidget()
        TimeScopesHighlightsWidget()
        TimeScopesDailyWidget()
        TimeScopesPulseTodayWidget()
        TimeScopesPulseWeeklyWidget()
        TimeScopesPulsePrescriptionsWidget()
        TimeScopesPulseJournalWidget()
    }
}
