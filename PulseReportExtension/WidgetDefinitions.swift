import AppIntents
import SwiftUI
import WidgetKit

private let timelineRefresh: TimeInterval = 15 * 60

private func makeTimeline<Entry: TimelineEntry>(_ entry: Entry) -> Timeline<Entry> {
    Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(timelineRefresh)))
}

private func loadSnapshot() -> WidgetSnapshot {
    WidgetSnapshotStore().loadSnapshot()
}

struct AddPulseJournalEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Pulse Entry"
    static var description = IntentDescription("Add a quick pulse journal entry.")

    func perform() async throws -> some IntentResult {
        PulseJournalWidgetStore.addEntry(note: PulseJournalWidgetStore.quickNote())
        return .result()
    }
}

private enum PulseJournalWidgetStore {
    private static let storeKey = "PulseJournalEntries"

    private static var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private struct StoredEntry: Codable {
        let id: UUID
        let date: Date
        let note: String
    }

    static func quickNote() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "Quick entry \(formatter.string(from: Date()))"
    }

    static func addEntry(note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let defaults = UserDefaults(suiteName: WidgetSharedConstants.appGroupID) else {
            return
        }
        var entries = loadEntries(from: defaults)
        entries.insert(StoredEntry(id: UUID(), date: Date(), note: trimmed), at: 0)
        persist(entries, to: defaults)
        updateSnapshot(with: entries.first)
    }

    private static func loadEntries(from defaults: UserDefaults) -> [StoredEntry] {
        guard let data = defaults.data(forKey: storeKey),
              let decoded = try? decoder.decode([StoredEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func persist(_ entries: [StoredEntry], to defaults: UserDefaults) {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: storeKey)
    }

    private static func updateSnapshot(with entry: StoredEntry?) {
        guard let entry else { return }
        let store = WidgetSnapshotStore()
        store.updateSnapshot { snapshot in
            var recentEntries = snapshot.pulse.recentEntries
            let journalEntry = WidgetSnapshot.Pulse.JournalEntry(date: entry.date, note: entry.note)
            recentEntries.insert(journalEntry, at: 0)
            recentEntries = Array(recentEntries.prefix(3))
            let updatedPulse = WidgetSnapshot.Pulse(
                todaySeries: snapshot.pulse.todaySeries,
                todayMax: snapshot.pulse.todayMax,
                currentFraction: snapshot.pulse.currentFraction,
                weeklyDays: snapshot.pulse.weeklyDays,
                weeklyPatternText: snapshot.pulse.weeklyPatternText,
                weeklyPeakText: snapshot.pulse.weeklyPeakText,
                weeklyLowText: snapshot.pulse.weeklyLowText,
                prescriptions: snapshot.pulse.prescriptions,
                journalPrompt: snapshot.pulse.journalPrompt,
                recentEntries: recentEntries
            )
            return WidgetSnapshot(
                updatedAt: Date(),
                profile: snapshot.profile,
                elapsed: snapshot.elapsed,
                milestones: snapshot.milestones,
                highlights: snapshot.highlights,
                daily: snapshot.daily,
                pulse: updatedPulse
            )
        }
    }
}

enum ProfileMetric: String, AppEnum {
    case age
    case monthsLeft
    case weeksLeft
    case daysLeft

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Profile Metric")
    static var caseDisplayRepresentations: [ProfileMetric: DisplayRepresentation] = [
        .age: "Age",
        .monthsLeft: "Months Left",
        .weeksLeft: "Weeks Left",
        .daysLeft: "Days Left",
    ]
}

struct ProfileWidgetConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Profile Widget"
    static var description = IntentDescription("Choose which profile value is highlighted.")

    @Parameter(title: "Primary Metric")
    var primaryMetric: ProfileMetric

    init() {
        self.primaryMetric = .age
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$primaryMetric)")
    }
}

struct ProfileWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let configuration: ProfileWidgetConfigurationIntent
}

struct ProfileWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ProfileWidgetEntry {
        ProfileWidgetEntry(date: Date(), snapshot: .empty, configuration: ProfileWidgetConfigurationIntent())
    }

    func snapshot(for configuration: ProfileWidgetConfigurationIntent, in context: Context) async -> ProfileWidgetEntry {
        ProfileWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration)
    }

    func timeline(for configuration: ProfileWidgetConfigurationIntent, in context: Context) async -> Timeline<ProfileWidgetEntry> {
        makeTimeline(ProfileWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration))
    }
}

enum ElapsedMetric: String, AppEnum {
    case months
    case weeks
    case days
    case hours
    case minutes
    case seconds

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Elapsed Metric")
    static var caseDisplayRepresentations: [ElapsedMetric: DisplayRepresentation] = [
        .months: "Months",
        .weeks: "Weeks",
        .days: "Days",
        .hours: "Hours",
        .minutes: "Minutes",
        .seconds: "Seconds",
    ]
}

struct ElapsedWidgetConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Elapsed Time Widget"
    static var description = IntentDescription("Choose which elapsed value is highlighted.")

    @Parameter(title: "Primary Metric")
    var primaryMetric: ElapsedMetric

    init() {
        self.primaryMetric = .days
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$primaryMetric)")
    }
}

struct ElapsedWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let configuration: ElapsedWidgetConfigurationIntent
}

struct ElapsedWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ElapsedWidgetEntry {
        ElapsedWidgetEntry(date: Date(), snapshot: .empty, configuration: ElapsedWidgetConfigurationIntent())
    }

    func snapshot(for configuration: ElapsedWidgetConfigurationIntent, in context: Context) async -> ElapsedWidgetEntry {
        ElapsedWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration)
    }

    func timeline(for configuration: ElapsedWidgetConfigurationIntent, in context: Context) async -> Timeline<ElapsedWidgetEntry> {
        makeTimeline(ElapsedWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration))
    }
}

enum MilestonesMetric: String, AppEnum {
    case yearsUntilNextDecade
    case daysUntilNextBirthday
    case weekdaysRemaining

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Milestone Metric")
    static var caseDisplayRepresentations: [MilestonesMetric: DisplayRepresentation] = [
        .yearsUntilNextDecade: "Years Until Next Decade",
        .daysUntilNextBirthday: "Days Until Next Birthday",
        .weekdaysRemaining: "Weekdays Remaining",
    ]
}

struct MilestonesWidgetConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Milestones Widget"
    static var description = IntentDescription("Choose which milestone value is highlighted.")

    @Parameter(title: "Primary Metric")
    var primaryMetric: MilestonesMetric

    init() {
        self.primaryMetric = .yearsUntilNextDecade
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$primaryMetric)")
    }
}

struct MilestonesWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let configuration: MilestonesWidgetConfigurationIntent
}

struct MilestonesWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MilestonesWidgetEntry {
        MilestonesWidgetEntry(date: Date(), snapshot: .empty, configuration: MilestonesWidgetConfigurationIntent())
    }

    func snapshot(for configuration: MilestonesWidgetConfigurationIntent, in context: Context) async -> MilestonesWidgetEntry {
        MilestonesWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration)
    }

    func timeline(for configuration: MilestonesWidgetConfigurationIntent, in context: Context) async -> Timeline<MilestonesWidgetEntry> {
        makeTimeline(MilestonesWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration))
    }
}

enum HighlightsMetric: String, AppEnum {
    case yearRemaining
    case nextChristmas
    case remainingMondays

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Highlight Metric")
    static var caseDisplayRepresentations: [HighlightsMetric: DisplayRepresentation] = [
        .yearRemaining: "Year Remaining",
        .nextChristmas: "Next Christmas",
        .remainingMondays: "Remaining Mondays",
    ]
}

struct HighlightsWidgetConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Highlights Widget"
    static var description = IntentDescription("Choose which highlight value is displayed.")

    @Parameter(title: "Primary Metric")
    var primaryMetric: HighlightsMetric

    init() {
        self.primaryMetric = .yearRemaining
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$primaryMetric)")
    }
}

struct HighlightsWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let configuration: HighlightsWidgetConfigurationIntent
}

struct HighlightsWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HighlightsWidgetEntry {
        HighlightsWidgetEntry(date: Date(), snapshot: .empty, configuration: HighlightsWidgetConfigurationIntent())
    }

    func snapshot(for configuration: HighlightsWidgetConfigurationIntent, in context: Context) async -> HighlightsWidgetEntry {
        HighlightsWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration)
    }

    func timeline(for configuration: HighlightsWidgetConfigurationIntent, in context: Context) async -> Timeline<HighlightsWidgetEntry> {
        makeTimeline(HighlightsWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration))
    }
}

enum DailyMetric: String, AppEnum {
    case nextHour
    case sun
    case timeLeft
    case freeTime
    case allocatedTime

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Daily Metric")
    static var caseDisplayRepresentations: [DailyMetric: DisplayRepresentation] = [
        .nextHour: "Until Next Hour",
        .sun: "Sun Window",
        .timeLeft: "Time Left Today",
        .freeTime: "Free Time",
        .allocatedTime: "Allocated Time",
    ]
}

struct DailyWidgetConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Daily Summary Widget"
    static var description = IntentDescription("Choose which daily value is displayed.")

    @Parameter(title: "Primary Metric")
    var primaryMetric: DailyMetric

    init() {
        self.primaryMetric = .timeLeft
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$primaryMetric)")
    }
}

struct DailyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let configuration: DailyWidgetConfigurationIntent
}

struct DailyWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DailyWidgetEntry {
        DailyWidgetEntry(date: Date(), snapshot: .empty, configuration: DailyWidgetConfigurationIntent())
    }

    func snapshot(for configuration: DailyWidgetConfigurationIntent, in context: Context) async -> DailyWidgetEntry {
        DailyWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration)
    }

    func timeline(for configuration: DailyWidgetConfigurationIntent, in context: Context) async -> Timeline<DailyWidgetEntry> {
        makeTimeline(DailyWidgetEntry(date: Date(), snapshot: loadSnapshot(), configuration: configuration))
    }
}

struct PulseWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct PulseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseWidgetEntry {
        PulseWidgetEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (PulseWidgetEntry) -> Void) {
        completion(PulseWidgetEntry(date: Date(), snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseWidgetEntry>) -> Void) {
        completion(makeTimeline(PulseWidgetEntry(date: Date(), snapshot: loadSnapshot())))
    }
}

private struct MetricDisplay {
    let label: String
    let valueText: String
    let value: Double
    let progressValue: Double
    let minValue: Double
    let maxValue: Double
    let minLabel: String
    let maxLabel: String

    var normalized: Double {
        normalizedValue(progressValue, min: minValue, max: maxValue)
    }
}

private func displayName(_ name: String) -> String {
    name.isEmpty ? "—" : name
}

private func normalizedValue(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    guard maxValue > minValue else { return 0 }
    let clamped = Swift.min(maxValue, Swift.max(minValue, value))
    return (clamped - minValue) / (maxValue - minValue)
}

private func percentValue(_ text: String) -> Double {
    let trimmed = text.replacingOccurrences(of: "%", with: "")
    let value = Double(trimmed) ?? 0
    return Swift.min(100, Swift.max(0, value))
}

private func profileDisplay(_ metric: ProfileMetric, profile: WidgetSnapshot.Profile) -> MetricDisplay {
    switch metric {
    case .age:
        return MetricDisplay(
            label: "Age",
            valueText: "\(profile.age)",
            value: Double(profile.age),
            progressValue: Double(profile.age),
            minValue: 0,
            maxValue: 120,
            minLabel: "0",
            maxLabel: "120"
        )
    case .monthsLeft:
        return MetricDisplay(
            label: "Months Left",
            valueText: "\(profile.monthsLeft)",
            value: Double(profile.monthsLeft),
            progressValue: 1200 - Double(profile.monthsLeft),
            minValue: 0,
            maxValue: 1200,
            minLabel: "0",
            maxLabel: "1200"
        )
    case .weeksLeft:
        return MetricDisplay(
            label: "Weeks Left",
            valueText: "\(profile.weeksLeft)",
            value: Double(profile.weeksLeft),
            progressValue: 5200 - Double(profile.weeksLeft),
            minValue: 0,
            maxValue: 5200,
            minLabel: "0",
            maxLabel: "5200"
        )
    case .daysLeft:
        return MetricDisplay(
            label: "Days Left",
            valueText: "\(profile.daysLeft)",
            value: Double(profile.daysLeft),
            progressValue: 36500 - Double(profile.daysLeft),
            minValue: 0,
            maxValue: 36500,
            minLabel: "0",
            maxLabel: "36500"
        )
    }
}

private func elapsedDisplay(_ metric: ElapsedMetric, elapsed: WidgetSnapshot.Elapsed) -> MetricDisplay {
    switch metric {
    case .months:
        return MetricDisplay(
            label: "Months",
            valueText: "\(elapsed.months)",
            value: Double(elapsed.months),
            progressValue: Double(elapsed.months),
            minValue: 0,
            maxValue: 1200,
            minLabel: "0",
            maxLabel: "1200"
        )
    case .weeks:
        return MetricDisplay(
            label: "Weeks",
            valueText: "\(elapsed.weeks)",
            value: Double(elapsed.weeks),
            progressValue: Double(elapsed.weeks),
            minValue: 0,
            maxValue: 5200,
            minLabel: "0",
            maxLabel: "5200"
        )
    case .days:
        return MetricDisplay(
            label: "Days",
            valueText: "\(elapsed.days)",
            value: Double(elapsed.days),
            progressValue: Double(elapsed.days),
            minValue: 0,
            maxValue: 36500,
            minLabel: "0",
            maxLabel: "36500"
        )
    case .hours:
        return MetricDisplay(
            label: "Hours",
            valueText: "\(elapsed.hours)",
            value: Double(elapsed.hours),
            progressValue: Double(elapsed.hours),
            minValue: 0,
            maxValue: 876000,
            minLabel: "0",
            maxLabel: "876k"
        )
    case .minutes:
        return MetricDisplay(
            label: "Minutes",
            valueText: "\(elapsed.minutes)",
            value: Double(elapsed.minutes),
            progressValue: Double(elapsed.minutes),
            minValue: 0,
            maxValue: 52560000,
            minLabel: "0",
            maxLabel: "52.6M"
        )
    case .seconds:
        return MetricDisplay(
            label: "Seconds",
            valueText: "\(elapsed.seconds)",
            value: Double(elapsed.seconds),
            progressValue: Double(elapsed.seconds),
            minValue: 0,
            maxValue: 3153600000,
            minLabel: "0",
            maxLabel: "3.15B"
        )
    }
}

private func milestonesDisplay(_ metric: MilestonesMetric, milestones: WidgetSnapshot.Milestones) -> MetricDisplay {
    switch metric {
    case .yearsUntilNextDecade:
        return MetricDisplay(
            label: "Next Age \(milestones.nextDecadeAge)",
            valueText: "\(milestones.yearsUntilNextDecade) years",
            value: Double(milestones.yearsUntilNextDecade),
            progressValue: 10 - Double(milestones.yearsUntilNextDecade),
            minValue: 0,
            maxValue: 10,
            minLabel: "0",
            maxLabel: "10"
        )
    case .daysUntilNextBirthday:
        return MetricDisplay(
            label: "Next Birthday",
            valueText: "\(milestones.daysUntilNextBirthday) days",
            value: Double(milestones.daysUntilNextBirthday),
            progressValue: 366 - Double(milestones.daysUntilNextBirthday),
            minValue: 0,
            maxValue: 366,
            minLabel: "0",
            maxLabel: "366"
        )
    case .weekdaysRemaining:
        return MetricDisplay(
            label: "Weekdays Remaining",
            valueText: "\(milestones.weekdaysRemaining) days",
            value: Double(milestones.weekdaysRemaining),
            progressValue: 20000 - Double(milestones.weekdaysRemaining),
            minValue: 0,
            maxValue: 20000,
            minLabel: "0",
            maxLabel: "20000"
        )
    }
}

private func highlightsDisplay(_ metric: HighlightsMetric, highlights: WidgetSnapshot.Highlights) -> MetricDisplay {
    switch metric {
    case .yearRemaining:
        return MetricDisplay(
            label: "Year Remaining",
            valueText: "\(highlights.yearRemainingDays) days",
            value: Double(highlights.yearRemainingDays),
            progressValue: 366 - Double(highlights.yearRemainingDays),
            minValue: 0,
            maxValue: 366,
            minLabel: "0",
            maxLabel: "366"
        )
    case .nextChristmas:
        return MetricDisplay(
            label: "Next Christmas",
            valueText: "\(highlights.nextChristmasDays) days",
            value: Double(highlights.nextChristmasDays),
            progressValue: 366 - Double(highlights.nextChristmasDays),
            minValue: 0,
            maxValue: 366,
            minLabel: "0",
            maxLabel: "366"
        )
    case .remainingMondays:
        return MetricDisplay(
            label: "Remaining Mondays",
            valueText: "\(highlights.remainingMondays)",
            value: Double(highlights.remainingMondays),
            progressValue: 60 - Double(highlights.remainingMondays),
            minValue: 0,
            maxValue: 60,
            minLabel: "0",
            maxLabel: "60"
        )
    }
}

private func dailyDisplay(_ metric: DailyMetric, daily: WidgetSnapshot.DailySummary) -> MetricDisplay {
    switch metric {
    case .nextHour:
        return MetricDisplay(
            label: "Until Next Hour",
            valueText: "\(daily.nextHourText) \(daily.nextHourPercent)",
            value: percentValue(daily.nextHourPercent),
            progressValue: percentValue(daily.nextHourPercent),
            minValue: 0,
            maxValue: 100,
            minLabel: "0%",
            maxLabel: "100%"
        )
    case .sun:
        return MetricDisplay(
            label: daily.sunTitle,
            valueText: "\(daily.sunValueText) \(daily.sunPercentText)",
            value: percentValue(daily.sunPercentText),
            progressValue: percentValue(daily.sunPercentText),
            minValue: 0,
            maxValue: 100,
            minLabel: "0%",
            maxLabel: "100%"
        )
    case .timeLeft:
        return MetricDisplay(
            label: "Time Left Today",
            valueText: "\(daily.timeLeftText) \(daily.timeLeftPercent)",
            value: percentValue(daily.timeLeftPercent),
            progressValue: percentValue(daily.timeLeftPercent),
            minValue: 0,
            maxValue: 100,
            minLabel: "0%",
            maxLabel: "100%"
        )
    case .freeTime:
        return MetricDisplay(
            label: "Free Time",
            valueText: "\(daily.freeTimeText) \(daily.freeTimePercent)",
            value: percentValue(daily.freeTimePercent),
            progressValue: percentValue(daily.freeTimePercent),
            minValue: 0,
            maxValue: 100,
            minLabel: "0%",
            maxLabel: "100%"
        )
    case .allocatedTime:
        return MetricDisplay(
            label: "Allocated Time",
            valueText: "\(daily.allocatedTimeText) \(daily.allocatedTimePercent)",
            value: percentValue(daily.allocatedTimePercent),
            progressValue: percentValue(daily.allocatedTimePercent),
            minValue: 0,
            maxValue: 100,
            minLabel: "0%",
            maxLabel: "100%"
        )
    }
}

private struct WidgetCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let isMedium = family == .systemMedium
        let accent = Color.accentColor
        let gradient = LinearGradient(
            colors: [
                accent.opacity(0.45),
                accent.opacity(0.18),
                accent.opacity(0.05),
                .clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(isMedium ? .callout : .footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(gradient, for: .widget)
        .shadow(color: accent.opacity(0.25), radius: 8, x: 0, y: 0)
    }
}

private struct RangeBar: View {
    let normalized: Double
    let color: Color
    let height: CGFloat

    init(normalized: Double, color: Color, height: CGFloat = 10) {
        self.normalized = normalized
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let barHeight = proxy.size.height
            let clamped = Swift.min(1, Swift.max(0, normalized))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.15))
                    .frame(height: barHeight)
                Capsule()
                    .fill(color)
                    .frame(width: max(2, width * CGFloat(clamped)), height: barHeight)
            }
        }
        .frame(height: height)
    }
}

private struct RangeLabels: View {
    let minLabel: String
    let maxLabel: String
    let font: Font

    init(minLabel: String, maxLabel: String, font: Font = .caption) {
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.font = font
    }

    var body: some View {
        HStack {
            Text(minLabel)
                .font(font)
                .foregroundStyle(.secondary)
            Spacer()
            Text(maxLabel)
                .font(font)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

struct TimeScopesProfileWidgetView: View {
    let entry: ProfileWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let profile = entry.snapshot.profile
        let display = profileDisplay(entry.configuration.primaryMetric, profile: profile)
        let isMedium = family == .systemMedium
        let valueFont: Font = isMedium ? .title2 : .title3
        let labelFont: Font = isMedium ? .callout : .footnote
        let nameFont: Font = isMedium ? .headline : .subheadline
        let rangeFont: Font = isMedium ? .footnote : .caption
        let barHeight: CGFloat = isMedium ? 12 : 10
        WidgetCard(title: "Profile") {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName(profile.name))
                    .font(nameFont)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(display.label)")
                    .font(labelFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(display.valueText)
                    .font(valueFont)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                RangeBar(normalized: display.normalized, color: .accentColor, height: barHeight)
                    .frame(maxWidth: .infinity)
                RangeLabels(minLabel: display.minLabel, maxLabel: display.maxLabel, font: rangeFont)
            }
        }
    }
}

struct TimeScopesElapsedWidgetView: View {
    let entry: ElapsedWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let elapsed = entry.snapshot.elapsed
        let display = elapsedDisplay(entry.configuration.primaryMetric, elapsed: elapsed)
        let isMedium = family == .systemMedium
        let valueFont: Font = isMedium ? .title2 : .title3
        let labelFont: Font = isMedium ? .callout : .footnote
        let rangeFont: Font = isMedium ? .footnote : .caption
        let barHeight: CGFloat = isMedium ? 12 : 10
        WidgetCard(title: "Elapsed Time") {
            VStack(alignment: .leading, spacing: 6) {
                Text(display.label)
                    .font(labelFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(display.valueText)
                    .font(valueFont)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                RangeBar(normalized: display.normalized, color: .accentColor, height: barHeight)
                    .frame(maxWidth: .infinity)
                RangeLabels(minLabel: display.minLabel, maxLabel: display.maxLabel, font: rangeFont)
            }
        }
    }
}

struct TimeScopesMilestonesWidgetView: View {
    let entry: MilestonesWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let milestones = entry.snapshot.milestones
        let display = milestonesDisplay(entry.configuration.primaryMetric, milestones: milestones)
        let isMedium = family == .systemMedium
        let valueFont: Font = isMedium ? .title2 : .title3
        let labelFont: Font = isMedium ? .callout : .footnote
        let rangeFont: Font = isMedium ? .footnote : .caption
        let barHeight: CGFloat = isMedium ? 12 : 10
        WidgetCard(title: "Upcoming Milestones") {
            VStack(alignment: .leading, spacing: 6) {
                Text(display.label)
                    .font(labelFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(display.valueText)
                    .font(valueFont)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                RangeBar(normalized: display.normalized, color: .accentColor, height: barHeight)
                    .frame(maxWidth: .infinity)
                RangeLabels(minLabel: display.minLabel, maxLabel: display.maxLabel, font: rangeFont)
            }
        }
    }
}

struct TimeScopesHighlightsWidgetView: View {
    let entry: HighlightsWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let highlights = entry.snapshot.highlights
        let display = highlightsDisplay(entry.configuration.primaryMetric, highlights: highlights)
        let isMedium = family == .systemMedium
        let valueFont: Font = isMedium ? .title2 : .title3
        let labelFont: Font = isMedium ? .callout : .footnote
        let rangeFont: Font = isMedium ? .footnote : .caption
        let barHeight: CGFloat = isMedium ? 12 : 10
        WidgetCard(title: "Annual Highlights") {
            VStack(alignment: .leading, spacing: 6) {
                Text(display.label)
                    .font(labelFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(display.valueText)
                    .font(valueFont)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                RangeBar(normalized: display.normalized, color: .accentColor, height: barHeight)
                    .frame(maxWidth: .infinity)
                RangeLabels(minLabel: display.minLabel, maxLabel: display.maxLabel, font: rangeFont)
            }
        }
    }
}

struct TimeScopesDailyWidgetView: View {
    let entry: DailyWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let daily = entry.snapshot.daily
        let display = dailyDisplay(entry.configuration.primaryMetric, daily: daily)
        let isMedium = family == .systemMedium
        let valueFont: Font = isMedium ? .title2 : .title3
        let labelFont: Font = isMedium ? .callout : .footnote
        let rangeFont: Font = isMedium ? .footnote : .caption
        let barHeight: CGFloat = isMedium ? 12 : 10
        WidgetCard(title: "Daily Summary") {
            VStack(alignment: .leading, spacing: 6) {
                Text(display.label)
                    .font(labelFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(display.valueText)
                    .font(valueFont)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                RangeBar(normalized: display.normalized, color: .accentColor, height: barHeight)
                    .frame(maxWidth: .infinity)
                RangeLabels(minLabel: display.minLabel, maxLabel: display.maxLabel, font: rangeFont)
            }
        }
    }
}

private struct PulseLineChart: View {
    let values: [Double]
    let maxValue: Double
    let currentFraction: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let safeValues = values.count < 2 ? [0, 0] : values
            let count = safeValues.count
            let maxLoad = max(1, maxValue)
            let step = width / CGFloat(max(1, count - 1))

            Path { path in
                for index in 0..<count {
                    let x = CGFloat(index) * step
                    let normalized = min(1, safeValues[index] / maxLoad)
                    let y = height - CGFloat(normalized) * height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.accentColor, lineWidth: 2)

            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                for index in 0..<count {
                    let x = CGFloat(index) * step
                    let normalized = min(1, safeValues[index] / maxLoad)
                    let y = height - CGFloat(normalized) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(Color.accentColor.opacity(0.12))

            let clamped = min(1, max(0, currentFraction))
            let currentX = clamped * width
            Path { path in
                path.move(to: CGPoint(x: currentX, y: 0))
                path.addLine(to: CGPoint(x: currentX, y: height))
            }
            .stroke(Color.primary.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct PulseWeekBarChart: View {
    let days: [WidgetSnapshot.Pulse.Day]

    var body: some View {
        GeometryReader { proxy in
            let safeDays = days.isEmpty
                ? [
                    WidgetSnapshot.Pulse.Day(label: "M", intensity: 0),
                    WidgetSnapshot.Pulse.Day(label: "T", intensity: 0),
                    WidgetSnapshot.Pulse.Day(label: "W", intensity: 0),
                    WidgetSnapshot.Pulse.Day(label: "T", intensity: 0),
                    WidgetSnapshot.Pulse.Day(label: "F", intensity: 0),
                    WidgetSnapshot.Pulse.Day(label: "S", intensity: 0),
                    WidgetSnapshot.Pulse.Day(label: "S", intensity: 0),
                ]
                : days
            let spacing: CGFloat = 6
            let count = max(1, safeDays.count)
            let totalSpacing = spacing * CGFloat(max(0, count - 1))
            let barWidth = max(8, (proxy.size.width - totalSpacing) / CGFloat(count))

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(safeDays.enumerated()), id: \.offset) { _, day in
                    let height = max(10, proxy.size.height * CGFloat(day.intensity))
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.accentColor.opacity(0.8))
                            .frame(width: barWidth, height: height)
                        Text(day.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: barWidth, alignment: .center)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
    }
}

private struct PulsePrescriptionRow: View {
    let prescription: WidgetSnapshot.Pulse.Prescription

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(prescription.focus.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .leading)
            Text(prescription.title)
                .font(.caption)
                .lineLimit(2)
            Spacer(minLength: 8)
            Text(prescription.impact)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct PulseTodayStructureWidgetView: View {
    let entry: PulseWidgetEntry

    var body: some View {
        let pulse = entry.snapshot.pulse
        let values = pulse.todaySeries
        let maxValue = max(pulse.todayMax, values.max() ?? 0)
        let lastIndex = max(0, values.count - 1)
        let currentIndex = min(lastIndex, Int((pulse.currentFraction * Double(lastIndex)).rounded()))
        let currentValue = values.indices.contains(currentIndex) ? values[currentIndex] : 0
        WidgetCard(title: "Today Structure") {
            VStack(alignment: .leading, spacing: 6) {
                PulseLineChart(values: values, maxValue: maxValue, currentFraction: pulse.currentFraction)
                    .frame(height: 90)
                HStack {
                    Text("Now \(Int(currentValue))")
                    Spacer()
                    Text("Max \(Int(maxValue))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct PulseWeeklyRhythmWidgetView: View {
    let entry: PulseWidgetEntry

    var body: some View {
        let pulse = entry.snapshot.pulse
        WidgetCard(title: "Weekly Rhythm") {
            VStack(alignment: .leading, spacing: 6) {
                PulseWeekBarChart(days: pulse.weeklyDays)
                    .frame(height: 90)
                Text(pulse.weeklyPatternText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    Text("Peak \(pulse.weeklyPeakText)")
                    Spacer()
                    Text("Low \(pulse.weeklyLowText)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
    }
}

struct PulsePrescriptionsWidgetView: View {
    let entry: PulseWidgetEntry

    var body: some View {
        let pulse = entry.snapshot.pulse
        let items = Array(pulse.prescriptions.prefix(3))
        WidgetCard(title: "Prescriptions") {
            VStack(alignment: .leading, spacing: 6) {
                if items.isEmpty {
                    Text("No prescriptions yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items.indices, id: \.self) { index in
                        PulsePrescriptionRow(prescription: items[index])
                        if index < items.count - 1 {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
    }
}

struct PulseJournalWidgetView: View {
    let entry: PulseWidgetEntry

    var body: some View {
        let pulse = entry.snapshot.pulse
        WidgetCard(title: "Daily Journal") {
            VStack(alignment: .leading, spacing: 6) {
                Text(pulse.journalPrompt)
                    .font(.footnote)
                    .lineLimit(3)
                if let recent = pulse.recentEntries.first {
                    Text(recent.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Button(intent: AddPulseJournalEntryIntent()) {
                    Label("Add Entry", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
    }
}
