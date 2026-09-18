import Foundation

#if DEBUG
enum WidgetPreviewData {
    static let snapshot = WidgetSnapshot(
        updatedAt: Date(),
        profile: .init(name: "Morgan", age: 34, monthsLeft: 552, weeksLeft: 2398, daysLeft: 16786),
        elapsed: .init(
            months: 412,
            weeks: 1792,
            days: 12544,
            hours: 301056,
            minutes: 18063360,
            seconds: 1083801600
        ),
        milestones: .init(
            nextDecadeAge: 40,
            yearsUntilNextDecade: 6,
            daysUntilNextBirthday: 147,
            weekdaysRemaining: 7684
        ),
        highlights: .init(
            yearRemainingDays: 88,
            nextChristmasDays: 53,
            remainingMondays: 12
        ),
        daily: .init(
            nextHourText: "23m 14s",
            nextHourPercent: "61%",
            sunTitle: "Until Sunset",
            sunValueText: "2h 48m 05s",
            sunPercentText: "64%",
            timeLeftText: "9h 42m 11s",
            timeLeftPercent: "60%",
            freeTimeText: "5h 08m 00s",
            freeTimePercent: "21%",
            allocatedTimeText: "18h 52m 00s",
            allocatedTimePercent: "79%"
        ),
        pulse: .init(
            todaySeries: [0, 0, 0, 0, 0, 1, 2, 1, 3, 4, 3, 2, 3, 4, 4, 2, 3, 5, 4, 2, 1, 1, 0, 0],
            todayMax: 5,
            currentFraction: 0.58,
            weeklyDays: [
                .init(label: "Mon", intensity: 0.7),
                .init(label: "Tue", intensity: 0.9),
                .init(label: "Wed", intensity: 1.0),
                .init(label: "Thu", intensity: 0.8),
                .init(label: "Fri", intensity: 0.65),
                .init(label: "Sat", intensity: 0.3),
                .init(label: "Sun", intensity: 0.25),
            ],
            weeklyPatternText: "Wed is your peak-load day. Consider moving one deep task to Sun.",
            weeklyPeakText: "Wed 9h 40m",
            weeklyLowText: "Sun 2h 05m",
            prescriptions: [
                .init(focus: "Load", title: "Shift one block from Wed to Sun", impact: "Gap 7h 35m"),
                .init(focus: "Focus", title: "Protect a deep-work block in Morning 6-12", impact: "2h 10m free"),
                .init(focus: "Flex", title: "Batch 6 quick tasks into one block", impact: "6 items"),
            ],
            recentEntries: [
                .init(date: Date().addingTimeInterval(-3600), note: "Reduced one recurring meeting and reclaimed a focused block."),
                .init(date: Date().addingTimeInterval(-10800), note: "Front-loaded difficult work before noon to reduce context switching."),
                .init(date: Date().addingTimeInterval(-18000), note: "Prepared tomorrow's first task and removed one nonessential commitment."),
            ]
        )
    )

    static func profileIntent(metric: ProfileMetric) -> ProfileWidgetConfigurationIntent {
        let intent = ProfileWidgetConfigurationIntent()
        intent.primaryMetric = metric
        return intent
    }

    static func elapsedIntent(metric: ElapsedMetric) -> ElapsedWidgetConfigurationIntent {
        let intent = ElapsedWidgetConfigurationIntent()
        intent.primaryMetric = metric
        return intent
    }

    static func milestonesIntent(metric: MilestonesMetric) -> MilestonesWidgetConfigurationIntent {
        let intent = MilestonesWidgetConfigurationIntent()
        intent.primaryMetric = metric
        return intent
    }

    static func highlightsIntent(metric: HighlightsMetric) -> HighlightsWidgetConfigurationIntent {
        let intent = HighlightsWidgetConfigurationIntent()
        intent.primaryMetric = metric
        return intent
    }

    static func dailyIntent(metric: DailyMetric) -> DailyWidgetConfigurationIntent {
        let intent = DailyWidgetConfigurationIntent()
        intent.primaryMetric = metric
        return intent
    }

    static func profileEntry(metric: ProfileMetric) -> ProfileWidgetEntry {
        .init(date: Date(), snapshot: snapshot, configuration: profileIntent(metric: metric))
    }

    static func elapsedEntry(metric: ElapsedMetric) -> ElapsedWidgetEntry {
        .init(date: Date(), snapshot: snapshot, configuration: elapsedIntent(metric: metric))
    }

    static func milestonesEntry(metric: MilestonesMetric) -> MilestonesWidgetEntry {
        .init(date: Date(), snapshot: snapshot, configuration: milestonesIntent(metric: metric))
    }

    static func highlightsEntry(metric: HighlightsMetric) -> HighlightsWidgetEntry {
        .init(date: Date(), snapshot: snapshot, configuration: highlightsIntent(metric: metric))
    }

    static func dailyEntry(metric: DailyMetric) -> DailyWidgetEntry {
        .init(date: Date(), snapshot: snapshot, configuration: dailyIntent(metric: metric))
    }

    static var pulseEntry: PulseWidgetEntry {
        .init(date: Date(), snapshot: snapshot)
    }
}
#endif
