import SwiftUI
import WidgetKit

struct TimeScopesWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TimeScopesWidgetProvider: TimelineProvider {
    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> TimeScopesWidgetEntry {
        TimeScopesWidgetEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeScopesWidgetEntry) -> Void) {
        let snapshot = store.loadSnapshot()
        completion(TimeScopesWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeScopesWidgetEntry>) -> Void) {
        let snapshot = store.loadSnapshot()
        let entry = TimeScopesWidgetEntry(date: Date(), snapshot: snapshot)
        let refresh = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

private struct WidgetRow: Identifiable {
    let id: String
    let label: String
    let value: String
}

private struct WidgetSectionView: View {
    let title: String
    let rows: [WidgetRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            ForEach(rows) { row in
                HStack(spacing: 6) {
                    Text(row.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(row.value)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .containerBackground(.clear, for: .widget)
    }
}

private func displayName(_ name: String) -> String {
    name.isEmpty ? "—" : name
}

private struct TimeScopesProfileWidgetView: View {
    let entry: TimeScopesWidgetEntry

    var body: some View {
        let profile = entry.snapshot.profile
        let rows = [
            WidgetRow(id: "name", label: "Name", value: displayName(profile.name)),
            WidgetRow(id: "age", label: "Age", value: "\(profile.age)"),
            WidgetRow(id: "months", label: "Months Left", value: "\(profile.monthsLeft)"),
            WidgetRow(id: "weeks", label: "Weeks Left", value: "\(profile.weeksLeft)"),
            WidgetRow(id: "days", label: "Days Left", value: "\(profile.daysLeft)"),
        ]
        WidgetSectionView(title: "Profile", rows: rows)
    }
}

private struct TimeScopesElapsedWidgetView: View {
    let entry: TimeScopesWidgetEntry

    var body: some View {
        let elapsed = entry.snapshot.elapsed
        let rows = [
            WidgetRow(id: "months", label: "Months", value: "\(elapsed.months)"),
            WidgetRow(id: "weeks", label: "Weeks", value: "\(elapsed.weeks)"),
            WidgetRow(id: "days", label: "Days", value: "\(elapsed.days)"),
            WidgetRow(id: "hours", label: "Hours", value: "\(elapsed.hours)"),
            WidgetRow(id: "minutes", label: "Minutes", value: "\(elapsed.minutes)"),
            WidgetRow(id: "seconds", label: "Seconds", value: "\(elapsed.seconds)"),
        ]
        WidgetSectionView(title: "Elapsed Time", rows: rows)
    }
}

private struct TimeScopesMilestonesWidgetView: View {
    let entry: TimeScopesWidgetEntry

    var body: some View {
        let milestones = entry.snapshot.milestones
        let rows = [
            WidgetRow(id: "decade", label: "Next Age \(milestones.nextDecadeAge)", value: "\(milestones.yearsUntilNextDecade)y"),
            WidgetRow(id: "birthday", label: "Next Birthday", value: "\(milestones.daysUntilNextBirthday)d"),
            WidgetRow(id: "weekdays", label: "Weekdays Left", value: "\(milestones.weekdaysRemaining)d"),
        ]
        WidgetSectionView(title: "Upcoming Milestones", rows: rows)
    }
}

private struct TimeScopesHighlightsWidgetView: View {
    let entry: TimeScopesWidgetEntry

    var body: some View {
        let highlights = entry.snapshot.highlights
        let rows = [
            WidgetRow(id: "year", label: "Year Remaining", value: "\(highlights.yearRemainingDays)d"),
            WidgetRow(id: "christmas", label: "Next Christmas", value: "\(highlights.nextChristmasDays)d"),
            WidgetRow(id: "mondays", label: "Mondays Left", value: "\(highlights.remainingMondays)"),
        ]
        WidgetSectionView(title: "Annual Highlights", rows: rows)
    }
}

private struct TimeScopesDailyWidgetView: View {
    let entry: TimeScopesWidgetEntry

    var body: some View {
        let daily = entry.snapshot.daily
        let rows = [
            WidgetRow(id: "nextHour", label: "Until Next Hour", value: "\(daily.nextHourText) \(daily.nextHourPercent)"),
            WidgetRow(id: "sun", label: daily.sunTitle, value: "\(daily.sunValueText) \(daily.sunPercentText)"),
            WidgetRow(id: "today", label: "Time Left Today", value: "\(daily.timeLeftText) \(daily.timeLeftPercent)"),
            WidgetRow(id: "free", label: "Free Time", value: "\(daily.freeTimeText) \(daily.freeTimePercent)"),
            WidgetRow(id: "allocated", label: "Allocated Time", value: "\(daily.allocatedTimeText) \(daily.allocatedTimePercent)"),
        ]
        WidgetSectionView(title: "Daily Summary", rows: rows)
    }
}

struct TimeScopesProfileWidget: Widget {
    let kind: String = WidgetSharedConstants.profileWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeScopesWidgetProvider()) { entry in
            TimeScopesProfileWidgetView(entry: entry)
        }
        .configurationDisplayName("Profile")
        .description("Profile section")
        .supportedFamilies([.systemSmall])
    }
}

struct TimeScopesElapsedWidget: Widget {
    let kind: String = WidgetSharedConstants.elapsedWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeScopesWidgetProvider()) { entry in
            TimeScopesElapsedWidgetView(entry: entry)
        }
        .configurationDisplayName("Elapsed Time")
        .description("Elapsed time section")
        .supportedFamilies([.systemSmall])
    }
}

struct TimeScopesMilestonesWidget: Widget {
    let kind: String = WidgetSharedConstants.milestonesWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeScopesWidgetProvider()) { entry in
            TimeScopesMilestonesWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Milestones")
        .description("Upcoming milestones section")
        .supportedFamilies([.systemSmall])
    }
}

struct TimeScopesHighlightsWidget: Widget {
    let kind: String = WidgetSharedConstants.highlightsWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeScopesWidgetProvider()) { entry in
            TimeScopesHighlightsWidgetView(entry: entry)
        }
        .configurationDisplayName("Annual Highlights")
        .description("Annual highlights section")
        .supportedFamilies([.systemSmall])
    }
}

struct TimeScopesDailyWidget: Widget {
    let kind: String = WidgetSharedConstants.dailyWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeScopesWidgetProvider()) { entry in
            TimeScopesDailyWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Summary")
        .description("Daily summary section")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct TimeScopesWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeScopesProfileWidget()
        TimeScopesElapsedWidget()
        TimeScopesMilestonesWidget()
        TimeScopesHighlightsWidget()
        TimeScopesDailyWidget()
    }
}
