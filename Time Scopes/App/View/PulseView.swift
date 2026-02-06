//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-05.
//

import SwiftUI

struct PulseView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var userData: UserData
    @StateObject private var eventProvider = CalendarEventProvider()
    @StateObject private var reminderProvider = ReminderProvider()
    @StateObject private var journalStore = PulseJournalStore()

    @State private var isPresentingJournal = false
    @State private var journalDraft = ""
    @State private var editingEntry: PulseJournalEntry?
    @State private var entryToDelete: PulseJournalEntry?
    @State private var isConfirmingDelete = false
    @State private var currentPrompt = ""

    private let calendar = Calendar.autoupdatingCurrent
    private let widgetStore = WidgetSnapshotStore()
    private static let journalPrompts: [String] = [
        "What single change would make tomorrow feel lighter?",
        "What did you protect well today?",
        "Which task drained you the most, and why?",
        "What small win deserves recognition?",
        "Where did you say yes too quickly?",
        "What did you postpone that now feels heavier?",
        "What was the clearest moment of focus today?",
        "Which meeting or task could be half as long next time?",
        "What did you learn about your energy today?",
        "What was the most avoidable friction you faced?",
        "What should you stop doing for one week?",
        "What did you do that aligned with your priorities?",
        "Where did you underestimate time cost?",
        "What is one decision you can make in advance?",
        "What did you do that created calm for others?",
        "Which task can be simplified to one sentence?",
        "What is the smallest next step for your hardest task?",
        "What did you finish that was quietly important?",
        "Where did you feel rushed, and what caused it?",
        "What boundary did you maintain today?",
        "What would you repeat from today?",
        "What would you remove from today if you could?",
        "Which obligation felt least essential?",
        "What did you avoid that you should face tomorrow?",
        "What was the best use of a 30-minute block?",
        "What did you do to recover your energy?",
        "What was the most valuable conversation today?",
        "What did you do that created momentum?",
        "What could be automated or templated?",
        "What is one thing you can decline tomorrow?",
        "Where did you overcommit?",
        "What did you do that felt unnecessary?",
        "What would make your next week smoother?",
        "What did you say no to, and was it right?",
        "What was your most focused hour?",
        "What will you do first tomorrow, and why?",
        "What did you leave incomplete, and what is the next step?",
        "What would you tell your future self about today?",
        "What did you do that reduced risk?",
        "Where did you create slack or buffers?",
        "What was your highest leverage action today?",
        "What did you do that was truly optional?",
        "What did you do that created clarity?",
        "What obligation can be renegotiated?",
        "What did you do that was kind to your future self?",
        "What did you do that was hard but necessary?",
        "What did you do that improved your system?",
        "What did you do that improved your communication?",
        "What did you do that improved your environment?",
        "What is one thing you will do differently tomorrow?"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerSection
                    if let message = dataStatusMessage {
                        PulseCallout(title: "Data Status", detail: message)
                    }
                    todayStructureCard
                    weeklyRhythmCard
                    prescriptionCard
                    journalCard
                }
                .padding()
            }
            .glassScreen()
        }
        .onAppear {
            refreshPrompt()
            syncPulseWidgetSnapshot()
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            refreshData()
            syncPulseWidgetSnapshot()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshData()
                syncPulseWidgetSnapshot()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshData()
            syncPulseWidgetSnapshot()
        }
        .onReceive(journalStore.$entries) { _ in
            syncPulseWidgetSnapshot()
        }
        .sheet(isPresented: $isPresentingJournal) {
            PulseJournalComposer(
                title: editingEntry == nil ? "New Entry" : "Edit Entry",
                saveLabel: editingEntry == nil ? "Save" : "Update",
                prompt: currentPrompt,
                draft: $journalDraft
            ) { note in
                if let editingEntry {
                    journalStore.updateEntry(id: editingEntry.id, note: note)
                } else {
                    journalStore.addEntry(note: note)
                }
                journalDraft = ""
                editingEntry = nil
                isPresentingJournal = false
            }
        }
        .onChange(of: isPresentingJournal) { isPresented in
            if !isPresented {
                journalDraft = ""
                editingEntry = nil
            }
        }
        .confirmationDialog(
            "Delete entry?",
            isPresented: $isConfirmingDelete,
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                journalStore.deleteEntry(id: entry.id)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pulse")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Structure, rhythm, and actions for your time.")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }

    private var todayStructureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Today Structure",
                subtitle: "A functional map of the next 24 hours."
            )
            PulseDayLineChart(
                values: todayLoadSeries,
                maxValue: todayLoadMax,
                currentFraction: currentTimeFraction
            )
            .frame(height: 160)
            HStack {
                Text("Event + task count per hour")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .glassCard(showBorder: false)
    }

    private var weeklyRhythmCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Weekly Rhythm",
                subtitle: "Pressure and energy across the week."
            )
            WeeklyRhythmChart(days: weeklyRhythm, highlightDay: todayWeekdayLabel)
            PulseCallout(
                title: "Pattern",
                detail: weeklyPatternText
            )
            weeklyDetailSection
        }
        .glassCard(showBorder: false)
    }

    private var prescriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Actionable Prescriptions",
                subtitle: "Small shifts with measurable impact."
            )
            if prescriptions.isEmpty {
                Text("No prescriptions yet. Add events or reminders to personalize guidance.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(prescriptions.indices, id: \.self) { index in
                    PulsePrescriptionRow(prescription: prescriptions[index])
                    if index < prescriptions.count - 1 {
                        Divider().opacity(0.35)
                    }
                }
            }
        }
        .glassCard(showBorder: false)
    }

    private var journalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseSectionHeader(
                title: "Daily Journal",
                subtitle: "Capture what moved the day."
            )
            VStack(alignment: .leading, spacing: 10) {
                Text("Prompt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(currentPrompt)
                    .font(.callout)
            }
            Button("Write Entry") {
                beginNewEntry()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            if recentEntries.isEmpty {
                Text("No entries yet. Start with one sentence.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recentEntries) { entry in
                        PulseJournalRow(
                            entry: entry,
                            onEdit: { beginEdit(entry) },
                            onDelete: { promptDelete(entry) }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(showBorder: false)
    }

    private var todayLoadSeries: [Double] {
        let today = Date()
        return hourlyLoadSeries(for: today)
    }

    private var todayLoadMax: Double {
        todayLoadSeries.max() ?? 0
    }

    private var todayWeekdayLabel: String {
        PulseFormatters.weekdayFormatter.string(from: Date())
    }

    private var currentTimeFraction: Double {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        let duration = max(1, endOfDay.timeIntervalSince(startOfDay))
        let elapsed = now.timeIntervalSince(startOfDay)
        return min(1, max(0, elapsed / duration))
    }

    private var weeklyRhythm: [PulseDayIntensity] {
        weeklyLoads.map { PulseDayIntensity(day: $0.day, intensity: $0.intensity) }
    }

    private var prescriptions: [PulsePrescription] {
        var items: [PulsePrescription] = []
        let today = Date()
        let dayInterval = dayInterval(for: today)
        let events = eventProvider.events(on: today).filter { !$0.isAllDay }
        let reminders = reminderProvider.reminders(on: today)

        if let balance = weeklyLoadBalanceSuggestion() {
            items.append(balance)
        }

        if let focusWindow = focusTimeWindowSuggestion() {
            items.append(focusWindow)
        }

        if let longest = events.max(by: { clampedDuration(for: $0, in: dayInterval) < clampedDuration(for: $1, in: dayInterval) }) {
            let duration = clampedDuration(for: longest, in: dayInterval)
            if duration >= 90 * 60 {
                items.append(
                    PulsePrescription(
                        focus: "Recovery",
                        title: "Insert a 25m reset after \(longest.title)",
                        detail: "Long sessions benefit from a deliberate buffer.",
                        impact: "Protects 25m"
                    )
                )
            }
        }

        if reminders.count >= 4 {
            items.append(
                PulsePrescription(
                    focus: "Flex",
                    title: "Batch \(reminders.count) quick tasks into one block",
                    detail: "Reduce context switching during the afternoon.",
                    impact: "\(reminders.count) items"
                )
            )
        }

        if items.isEmpty {
            items.append(
                PulsePrescription(
                    focus: "Focus",
                    title: "Reserve one 45m deep-work block",
                    detail: "Protect a window for your most important task.",
                    impact: "45m"
                )
            )
        }

        return Array(items.prefix(3))
    }

    private var recentEntries: [PulseJournalEntry] {
        journalStore.entries(on: Date(), calendar: calendar)
    }

    private var dataStatusMessage: String? {
        var messages: [String] = []
        if !eventProvider.hasAccess {
            messages.append("Calendar access not granted.")
        } else if !eventProvider.hasCalendars {
            messages.append("No calendars found.")
        }

        if !reminderProvider.hasAccess {
            messages.append("Reminders access not granted.")
        } else if !reminderProvider.hasReminderLists {
            messages.append("No reminder lists found.")
        }

        return messages.isEmpty ? nil : messages.joined(separator: " ")
    }

    private var weeklyPatternText: String {
        let intensities = weeklyRhythm
        guard let maxDay = intensities.max(by: { $0.intensity < $1.intensity }),
              let minDay = intensities.min(by: { $0.intensity < $1.intensity }),
              maxDay.intensity > 0 else {
            return "Not enough data yet. Add events or reminders to reveal your weekly rhythm."
        }
        if maxDay.day == minDay.day {
            return "Your week is balanced so far. Keep the current distribution."
        }
        return "\(maxDay.day) is your peak-load day. Consider moving one deep task to \(minDay.day)."
    }

    private var weeklyDetailSection: some View {
        let summary = weeklySummary
        return VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                PulseSummaryCell(title: "Peak Day", value: summary.peakDayText)
                PulseSummaryCell(title: "Low Day", value: summary.lowDayText)
                PulseSummaryCell(title: "Week Events", value: summary.eventCountText)
                PulseSummaryCell(title: "Week Reminders", value: summary.reminderCountText)
                PulseSummaryCell(title: "Event Time", value: summary.eventTimeText)
                PulseSummaryCell(title: "Total Load", value: summary.totalLoadText)
                PulseSummaryCell(title: "Avg Load/Day", value: summary.averageLoadText)
                PulseSummaryCell(title: "Avg Reminders/Day", value: summary.averageRemindersText)
                PulseSummaryCell(title: "Distribution", value: summary.distributionText)
                PulseSummaryCell(title: "Free Time in Week", value: summary.freeTimeText)
            }
            if !weeklyTopEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Longest Sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(weeklyTopEvents) { event in
                        PulseWeeklyEventRow(event: event)
                    }
                }
            }
        }
    }

    private func weeklyLoadBalanceSuggestion() -> PulsePrescription? {
        let loads = weeklyLoads
        guard let maxDay = loads.max(by: { $0.loadMinutes < $1.loadMinutes }),
              let minDay = loads.min(by: { $0.loadMinutes < $1.loadMinutes }) else {
            return nil
        }
        let delta = maxDay.loadMinutes - minDay.loadMinutes
        guard delta >= 120 else {
            return nil
        }
        let deltaText = PulseFormatters.formatDuration(delta * 60)
        return PulsePrescription(
            focus: "Load",
            title: "Shift one block from \(maxDay.day) to \(minDay.day)",
            detail: "Peak day is heavier by \(deltaText).",
            impact: "Gap \(deltaText)"
        )
    }

    private func focusTimeWindowSuggestion() -> PulsePrescription? {
        let today = Date()
        let events = eventProvider.events(on: today).filter { !$0.isAllDay }
        let reminders = reminderProvider.reminders(on: today)

        let segments = [
            FocusSegment(label: "Morning 6-12", startHour: 6, endHour: 12),
            FocusSegment(label: "Afternoon 12-17", startHour: 12, endHour: 17),
            FocusSegment(label: "Evening 17-21", startHour: 17, endHour: 21)
        ]

        var loads: [(segment: FocusSegment, busyMinutes: Double, freeMinutes: Double)] = []

        for segment in segments {
            guard let interval = segmentInterval(for: today, startHour: segment.startHour, endHour: segment.endHour) else {
                continue
            }
            let eventMinutes = events.reduce(0.0) { total, event in
                total + clampedDuration(for: event, in: interval) / 60
            }
            let reminderMinutes = reminders.reduce(0.0) { total, reminder in
                guard !reminder.isAllDay else { return total }
                return interval.contains(reminder.dueDate) ? total + 15 : total
            }
            let segmentMinutes = Double((segment.endHour - segment.startHour) * 60)
            let busyMinutes = eventMinutes + reminderMinutes
            let freeMinutes = max(0, segmentMinutes - busyMinutes)
            loads.append((segment: segment, busyMinutes: busyMinutes, freeMinutes: freeMinutes))
        }

        guard let least = loads.min(by: { $0.busyMinutes < $1.busyMinutes }),
              let most = loads.max(by: { $0.busyMinutes < $1.busyMinutes }) else {
            return nil
        }

        guard least.freeMinutes >= 60 else {
            return nil
        }

        let freeText = PulseFormatters.formatDuration(least.freeMinutes * 60)
        return PulsePrescription(
            focus: "Focus",
            title: "Protect a deep-work block in \(least.segment.label)",
            detail: "Keep shallow tasks in \(most.segment.label) to separate focus time.",
            impact: "\(freeText) free"
        )
    }

    private func refreshData() {
        let interval = weekInterval(for: Date())
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
    }

    private func syncPulseWidgetSnapshot() {
        let pulseSnapshot = buildPulseSnapshot()
        let current = widgetStore.loadSnapshot()
        let snapshot = WidgetSnapshot(
            updatedAt: Date(),
            profile: current.profile,
            elapsed: current.elapsed,
            milestones: current.milestones,
            highlights: current.highlights,
            daily: current.daily,
            pulse: pulseSnapshot
        )
        widgetStore.saveSnapshot(snapshot)
    }

    private func buildPulseSnapshot() -> WidgetSnapshot.Pulse {
        let weeklyDays = weeklyRhythm.map {
            WidgetSnapshot.Pulse.Day(label: $0.day, intensity: $0.intensity)
        }
        let summary = weeklySummary
        let prompt = currentPrompt.isEmpty
            ? (PulseView.journalPrompts.randomElement() ?? "Write one sentence.")
            : currentPrompt
        let prescriptionsSnapshot = prescriptions.map {
            WidgetSnapshot.Pulse.Prescription(focus: $0.focus, title: $0.title, impact: $0.impact)
        }
        let journalEntries = journalStore.recentEntries(limit: 3).map {
            WidgetSnapshot.Pulse.JournalEntry(date: $0.date, note: $0.note)
        }
        return WidgetSnapshot.Pulse(
            todaySeries: todayLoadSeries,
            todayMax: todayLoadMax,
            currentFraction: currentTimeFraction,
            weeklyDays: weeklyDays,
            weeklyPatternText: weeklyPatternText,
            weeklyPeakText: summary.peakDayText,
            weeklyLowText: summary.lowDayText,
            prescriptions: prescriptionsSnapshot,
            journalPrompt: prompt,
            recentEntries: journalEntries
        )
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    private func weekInterval(for date: Date) -> DateInterval {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return interval
        }
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    private var weeklyLoads: [PulseDayLoad] {
        let today = Date()
        let weekStart = weekInterval(for: today).start
        var seeds: [PulseDayLoadSeed] = []

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let interval = dayInterval(for: day)
            let events = eventProvider.events(on: day).filter { !$0.isAllDay }
            let reminders = reminderProvider.reminders(on: day)
            let eventMinutes = events.reduce(0.0) { total, event in
                total + clampedDuration(for: event, in: interval) / 60
            }
            let reminderCount = reminders.count
            let reminderMinutes = Double(reminderCount) * 15
            let load = eventMinutes + reminderMinutes
            let label = PulseFormatters.weekdayFormatter.string(from: day)
            seeds.append(
                PulseDayLoadSeed(
                    day: label,
                    eventMinutes: eventMinutes,
                    reminderMinutes: reminderMinutes,
                    eventCount: events.count,
                    reminderCount: reminderCount,
                    loadMinutes: load
                )
            )
        }

        let maxLoad = seeds.map(\.loadMinutes).max() ?? 0
        return seeds.map { seed in
            PulseDayLoad(
                day: seed.day,
                loadMinutes: seed.loadMinutes,
                intensity: maxLoad > 0 ? seed.loadMinutes / maxLoad : 0,
                eventMinutes: seed.eventMinutes,
                reminderMinutes: seed.reminderMinutes,
                eventCount: seed.eventCount,
                reminderCount: seed.reminderCount
            )
        }
    }

    private func segmentInterval(for date: Date, startHour: Int, endHour: Int) -> DateInterval? {
        let startDay = calendar.startOfDay(for: date)
        guard let start = calendar.date(byAdding: .hour, value: startHour, to: startDay),
              let end = calendar.date(byAdding: .hour, value: endHour, to: startDay) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    private func clampedDuration(for event: CalendarEventItem, in interval: DateInterval) -> TimeInterval {
        let start = max(event.startDate, interval.start)
        let end = min(event.endDate, interval.end)
        return max(0, end.timeIntervalSince(start))
    }

    private func overlaps(start: Date, end: Date, in interval: DateInterval) -> Bool {
        end > interval.start && start < interval.end
    }

    private func reminderOverlaps(_ reminder: ReminderItem, in interval: DateInterval) -> Bool {
        guard !reminder.isAllDay else { return false }
        if let startDate = reminder.startDate {
            return overlaps(start: startDate, end: reminder.dueDate, in: interval)
        }
        return interval.contains(reminder.dueDate)
    }

    private func hourlyLoadSeries(for date: Date) -> [Double] {
        let calendar = Calendar.autoupdatingCurrent
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let dayInterval = DateInterval(start: dayStart, end: dayEnd)
        let events = eventProvider.events.filter {
            !$0.isAllDay && $0.endDate > dayInterval.start && $0.startDate < dayInterval.end
        }
        let reminders = reminderProvider.reminders.filter { reminder in
            if let startDate = reminder.startDate {
                return reminder.dueDate > dayInterval.start && startDate < dayInterval.end
            }
            return dayInterval.contains(reminder.dueDate)
        }

        var series: [Double] = []
        for hour in 0..<24 {
            guard let start = calendar.date(byAdding: .hour, value: hour, to: dayStart),
                  let end = calendar.date(byAdding: .hour, value: hour + 1, to: dayStart) else {
                series.append(0)
                continue
            }
            let interval = DateInterval(start: start, end: end)
            let eventHits = events.reduce(0) { total, event in
                total + (overlaps(start: event.startDate, end: event.endDate, in: interval) ? 1 : 0)
            }
            let reminderHits = reminders.reduce(0) { total, reminder in
                total + (reminderOverlaps(reminder, in: interval) ? 1 : 0)
            }
            series.append(Double(eventHits + reminderHits))
        }
        return series
    }

    private var weeklySummary: PulseWeeklySummary {
        let loads = weeklyLoads
        let totalEventCount = loads.reduce(0) { $0 + $1.eventCount }
        let totalReminderCount = loads.reduce(0) { $0 + $1.reminderCount }
        let totalEventMinutes = loads.reduce(0.0) { $0 + $1.eventMinutes }
        let totalLoadMinutes = loads.reduce(0.0) { $0 + $1.loadMinutes }
        let totalWeekMinutes = Double(7 * 24 * 60)
        let totalFreeMinutes = max(0, totalWeekMinutes - totalLoadMinutes)
        let averageLoad = loads.isEmpty ? 0 : totalLoadMinutes / Double(loads.count)
        let averageReminders = loads.isEmpty ? 0 : Double(totalReminderCount) / Double(loads.count)
        let hasLoad = totalLoadMinutes > 0

        let peak = loads.max(by: { $0.loadMinutes < $1.loadMinutes })
        let low = loads.min(by: { $0.loadMinutes < $1.loadMinutes })

        let peakDayText: String
        let lowDayText: String
        if hasLoad, let peak, let low {
            peakDayText = "\(peak.day) \(PulseFormatters.formatDuration(peak.loadMinutes * 60))"
            lowDayText = "\(low.day) \(PulseFormatters.formatDuration(low.loadMinutes * 60))"
        } else {
            peakDayText = "No data"
            lowDayText = "No data"
        }
        let distribution = distributionLabel(for: loads, hasLoad: hasLoad)

        return PulseWeeklySummary(
            peakDayText: peakDayText,
            lowDayText: lowDayText,
            eventCountText: "\(totalEventCount) events",
            reminderCountText: "\(totalReminderCount) items",
            eventTimeText: PulseFormatters.formatDuration(totalEventMinutes * 60),
            totalLoadText: PulseFormatters.formatDuration(totalLoadMinutes * 60),
            averageLoadText: PulseFormatters.formatDuration(averageLoad * 60),
            averageRemindersText: String(format: "%.1f", averageReminders),
            distributionText: distribution,
            freeTimeText: PulseFormatters.formatDuration(totalFreeMinutes * 60)
        )
    }

    private func distributionLabel(for loads: [PulseDayLoad], hasLoad: Bool) -> String {
        guard hasLoad else { return "No data" }
        let values = loads.map(\.loadMinutes)
        let mean = values.reduce(0.0, +) / Double(values.count)
        guard mean > 0 else { return "No data" }
        let variance = values.reduce(0.0) { total, value in
            let diff = value - mean
            return total + diff * diff
        } / Double(values.count)
        let std = sqrt(variance)
        let cv = std / mean
        if cv < 0.25 {
            return "Even"
        } else if cv < 0.5 {
            return "Slightly Skewed"
        } else if cv < 0.75 {
            return "Skewed"
        }
        return "Highly Skewed"
    }

    private var weeklyTopEvents: [PulseWeeklyEvent] {
        let interval = weekInterval(for: Date())
        let events = eventProvider.events.filter { !$0.isAllDay }
        let summaries = events.compactMap { event -> PulseWeeklyEvent? in
            let duration = clampedDuration(for: event, in: interval)
            guard duration > 0 else { return nil }
            let day = PulseFormatters.weekdayFormatter.string(from: event.startDate)
            return PulseWeeklyEvent(day: day, title: event.title, duration: duration)
        }
        return Array(summaries.sorted { $0.duration > $1.duration }.prefix(3))
    }

    private func beginNewEntry() {
        editingEntry = nil
        journalDraft = ""
        refreshPrompt()
        isPresentingJournal = true
    }

    private func beginEdit(_ entry: PulseJournalEntry) {
        editingEntry = entry
        journalDraft = entry.note
        isPresentingJournal = true
    }

    private func refreshPrompt() {
        currentPrompt = PulseView.journalPrompts.randomElement() ?? ""
    }

    private func promptDelete(_ entry: PulseJournalEntry) {
        entryToDelete = entry
        isConfirmingDelete = true
    }
}

private struct PulseMetric: Identifiable {
    let id = UUID()
    let title: String
    let duration: TimeInterval
    let detail: String
    let progress: Double
    let tint: Color
}

private struct PulseDayIntensity: Identifiable {
    let id = UUID()
    let day: String
    let intensity: Double
}

private struct PulseDayLoad: Identifiable {
    let id = UUID()
    let day: String
    let loadMinutes: Double
    let intensity: Double
    let eventMinutes: Double
    let reminderMinutes: Double
    let eventCount: Int
    let reminderCount: Int
}

private struct PulseDayLoadSeed {
    let day: String
    let eventMinutes: Double
    let reminderMinutes: Double
    let eventCount: Int
    let reminderCount: Int
    let loadMinutes: Double
}

private struct FocusSegment {
    let label: String
    let startHour: Int
    let endHour: Int
}

private struct PulseWeeklySummary {
    let peakDayText: String
    let lowDayText: String
    let eventCountText: String
    let reminderCountText: String
    let eventTimeText: String
    let totalLoadText: String
    let averageLoadText: String
    let averageRemindersText: String
    let distributionText: String
    let freeTimeText: String
}

private struct PulseWeeklyEvent: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let duration: TimeInterval
}

private struct PulsePrescription: Identifiable {
    let id = UUID()
    let focus: String
    let title: String
    let detail: String
    let impact: String
}

private struct PulseSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulseMetricCard: View {
    let metric: PulseMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(metric.title)
                    .font(.subheadline)
                Spacer()
                Text(PulseFormatters.formatDuration(metric.duration))
                    .font(.headline)
            }
            ProgressView(value: metric.progress)
                .tint(metric.tint)
            Text(metric.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseSummaryCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseWeeklyEventRow: View {
    let event: PulseWeeklyEvent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(event.day)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            Text(event.title)
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(PulseFormatters.formatDuration(event.duration))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseDayBar: View {
    let day: PulseDayIntensity

    private var height: CGFloat {
        max(16, 110 * day.intensity)
    }

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.75))
                .frame(width: 18, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
            Text(day.day)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WeeklyRhythmChart: View {
    let days: [PulseDayIntensity]
    let highlightDay: String

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 8
            let count = max(1, days.count)
            let totalSpacing = spacing * CGFloat(max(0, count - 1))
            let barWidth = max(10, (proxy.size.width - totalSpacing) / CGFloat(count))

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(days) { day in
                    let isHighlight = day.day == highlightDay
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isHighlight ? Color.green : Color.accentColor.opacity(0.75))
                            .frame(width: barWidth, height: max(16, 110 * day.intensity))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                            )
                        Text(day.day)
                            .font(.caption2)
                            .foregroundStyle(isHighlight ? Color.green : .secondary)
                            .frame(width: barWidth, alignment: .center)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }
}

private struct PulseDayLineChart: View {
    let values: [Double]
    let maxValue: Double
    let currentFraction: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let count = max(2, values.count)
            let maxLoad = max(1, maxValue)
            let step = width / CGFloat(count - 1)

            Path { path in
                for index in 0..<count {
                    let x = CGFloat(index) * step
                    let yValue = values[index]
                    let normalized = min(1, yValue / maxLoad)
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
                    let yValue = values[index]
                    let normalized = min(1, yValue / maxLoad)
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
            .stroke(Color.primary.opacity(0.35), lineWidth: 1)

            HStack {
                Text("0")
                Spacer()
                Text("6")
                Spacer()
                Text("12")
                Spacer()
                Text("18")
                Spacer()
                Text("24")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, height - 16)
        }
    }
}

private struct PulsePrescriptionRow: View {
    let prescription: PulsePrescription

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PulseTag(text: prescription.focus)
            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(prescription.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(prescription.impact)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulseTag: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.2))
            )
            .foregroundStyle(Color.accentColor)
    }
}

private struct PulseCallout: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.callout)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseJournalRow: View {
    let entry: PulseJournalEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(PulseFormatters.shortDateFormatter.string(from: entry.date))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(PulseFormatters.timeFormatter.string(from: entry.date))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text(entry.note)
                .font(.callout)
                .lineLimit(2)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            VStack {
                Spacer(minLength: 0)
                Menu {
                    Button("Edit") {
                        onEdit()
                    }
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24, alignment: .center)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct PulseJournalComposer: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let saveLabel: String
    let prompt: String
    @Binding var draft: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Prompt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(prompt)
                        .font(.callout)
                }
                Text("Write one clear sentence about your day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $draft)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.thinMaterial)
                    )
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveLabel) {
                        onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private enum PulseFormatters {
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    static func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "0m" }
        return durationFormatter.string(from: duration) ?? "0m"
    }
}

#Preview {
    PulseView()
        .environmentObject(UserData())
}
