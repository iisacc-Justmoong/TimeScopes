//
//  PulseView+Data.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation
import SwiftUI

extension PulseView {
    func scrollTarget(for route: AppDeepLink) -> PulseScrollTarget? {
        guard route.tab == .pulse else { return nil }
        switch route.section {
        case "todayStructure":
            return .todayStructure
        case "weeklyRhythm":
            return .weeklyRhythm
        case "prescriptions":
            return .prescriptions
        case "journal":
            return .journal
        default:
            return nil
        }
    }

    func scrollToDeepLinkIfNeeded(using proxy: ScrollViewProxy) {
        guard let route = deepLinkCenter.route,
              let target = scrollTarget(for: route) else {
            return
        }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(target, anchor: .top)
            }
        }
    }

    func performPeriodicRefreshIfNeeded(at now: Date, force: Bool = false) {
        guard force || isPeriodicRefreshDue(at: now) else { return }
        lastPeriodicRefresh = now
        journalStore.reload()
        refreshData()
        syncPulseWidgetSnapshot(requestTimelineReload: force)
    }

    func isPeriodicRefreshDue(at now: Date) -> Bool {
        guard scenePhase == .active, isViewVisible else { return false }
        return now.timeIntervalSince(lastPeriodicRefresh) >= 60
    }

    var todayLoadSeries: [Double] {
        let today = Date()
        return hourlyLoadSeries(for: today)
    }

    var todayLoadMax: Double {
        todayLoadSeries.max() ?? 0
    }

    var todayWeekdayLabel: String {
        PulseFormatters.weekdayFormatter.string(from: Date())
    }

    var currentTimeFraction: Double {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        let duration = max(1, endOfDay.timeIntervalSince(startOfDay))
        let elapsed = now.timeIntervalSince(startOfDay)
        return min(1, max(0, elapsed / duration))
    }

    var weeklyRhythm: [PulseDayIntensity] {
        weeklyLoads.map { PulseDayIntensity(day: $0.day, intensity: $0.intensity) }
    }

    var prescriptions: [PulsePrescription] {
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

    var recentEntries: [PulseJournalEntry] {
        journalStore.entries(on: Date(), calendar: calendar)
    }

    var dataStatusMessage: String? {
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

    var weeklyPatternText: String {
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

    var weeklySummary: PulseWeeklySummary {
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

    var weeklyTopEvents: [PulseWeeklyEvent] {
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

    func weeklyLoadBalanceSuggestion() -> PulsePrescription? {
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

    func focusTimeWindowSuggestion() -> PulsePrescription? {
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

    func refreshData() {
        let interval = weekInterval(for: Date())
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
    }

    func syncPulseWidgetSnapshot(requestTimelineReload: Bool = true) {
        let pulseSnapshot = buildPulseSnapshot()
        widgetStore.updateSnapshot(requestTimelineReload: requestTimelineReload) { current in
            WidgetSnapshot(
                updatedAt: Date(),
                profile: current.profile,
                elapsed: current.elapsed,
                milestones: current.milestones,
                highlights: current.highlights,
                daily: current.daily,
                pulse: pulseSnapshot
            )
        }
    }

    func buildPulseSnapshot() -> WidgetSnapshot.Pulse {
        let weeklyDays = weeklyRhythm.map {
            WidgetSnapshot.Pulse.Day(label: $0.day, intensity: $0.intensity)
        }
        let summary = weeklySummary
        let prompt = currentPrompt.isEmpty
            ? (PulseJournalPrompts.all.randomElement() ?? "Write one sentence.")
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

    func dayInterval(for date: Date) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    func weekInterval(for date: Date) -> DateInterval {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return interval
        }
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    var weeklyLoads: [PulseDayLoad] {
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

    func segmentInterval(for date: Date, startHour: Int, endHour: Int) -> DateInterval? {
        let startDay = calendar.startOfDay(for: date)
        guard let start = calendar.date(byAdding: .hour, value: startHour, to: startDay),
              let end = calendar.date(byAdding: .hour, value: endHour, to: startDay) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    func clampedDuration(for event: CalendarEventItem, in interval: DateInterval) -> TimeInterval {
        let start = max(event.startDate, interval.start)
        let end = min(event.endDate, interval.end)
        return max(0, end.timeIntervalSince(start))
    }

    func hourlyLoadSeries(for date: Date) -> [Double] {
        let eventSpans = eventProvider.events.compactMap { event -> PulseHourlyLoadCalculator.Span? in
            guard !event.isAllDay else { return nil }
            return PulseHourlyLoadCalculator.Span(start: event.startDate, end: event.endDate)
        }
        var reminderSpans: [PulseHourlyLoadCalculator.Span] = []
        var reminderMoments: [Date] = []
        for reminder in reminderProvider.allReminders where !reminder.isAllDay {
            if let startDate = reminder.startDate, reminder.dueDate > startDate {
                reminderSpans.append(PulseHourlyLoadCalculator.Span(start: startDate, end: reminder.dueDate))
            } else {
                reminderMoments.append(reminder.dueDate)
            }
        }
        return PulseHourlyLoadCalculator.makeSeries(
            for: date,
            calendar: calendar,
            eventSpans: eventSpans,
            reminderSpans: reminderSpans,
            reminderMoments: reminderMoments
        )
    }

    func distributionLabel(for loads: [PulseDayLoad], hasLoad: Bool) -> String {
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

    func beginNewEntry() {
        editingEntry = nil
        journalDraft = ""
        refreshPrompt()
        isPresentingJournal = true
    }

    func presentComposerIfRequestedFromWidget() {
        guard PulseJournalWidgetAction.consumeOpenComposerRequest() else { return }
        beginNewEntry()
    }

    func beginEdit(_ entry: PulseJournalEntry) {
        editingEntry = entry
        journalDraft = entry.note
        isPresentingJournal = true
    }

    func refreshPrompt() {
        currentPrompt = PulseJournalPrompts.all.randomElement() ?? ""
    }

    func promptDelete(_ entry: PulseJournalEntry) {
        entryToDelete = entry
        isConfirmingDelete = true
    }
}
