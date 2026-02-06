import Foundation

enum WidgetSharedConstants {
    static let appGroupID = "group.com.iisacc.timescopes"
    static let snapshotFileName = "widget_snapshot.json"
    static let profileWidgetKind = "TimeScopesProfileWidget"
    static let elapsedWidgetKind = "TimeScopesElapsedWidget"
    static let milestonesWidgetKind = "TimeScopesMilestonesWidget"
    static let highlightsWidgetKind = "TimeScopesHighlightsWidget"
    static let dailyWidgetKind = "TimeScopesDailyWidget"
    static let allWidgetKinds = [
        profileWidgetKind,
        elapsedWidgetKind,
        milestonesWidgetKind,
        highlightsWidgetKind,
        dailyWidgetKind,
    ]
}
