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
        if #available(iOSApplicationExtension 18.0, *) {
            TimeScopesPulseJournalControlWidget()
        }
    }
}
