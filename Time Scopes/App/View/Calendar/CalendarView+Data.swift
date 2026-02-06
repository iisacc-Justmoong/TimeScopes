//
//  CalendarView+Data.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation
import SwiftUI

extension CalendarView {
    func weekdaySymbols(for calendar: Calendar) -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    func monthMetadata(for monthStart: Date, calendar: Calendar) -> MonthMetadata {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        return MonthMetadata(monthStart: monthStart, daysInMonth: daysInMonth, leadingEmptyDays: leadingEmptyDays)
    }

    func markers(for date: Date, calendar: Calendar) -> [CalendarMarker] {
        var markers: [CalendarMarker] = []
        let year = calendar.component(.year, from: date)

        if calendar.isDate(date, inSameDayAs: dateProvider.now()) {
            markers.append(CalendarMarker(color: .accentColor))
        }

        if let birthdayInYear = birthdayDate(in: year, calendar: calendar),
           calendar.isDate(date, inSameDayAs: birthdayInYear) {
            markers.append(CalendarMarker(color: .pink))
        }

        if calendar.isDate(date, inSameDayAs: userData.deathDate) {
            markers.append(CalendarMarker(color: .orange))
        }

        let remainingSlotsAfterFixed = max(0, 3 - markers.count)
        let eventColors = eventProvider.markerColors(for: date, limit: remainingSlotsAfterFixed)
        markers.append(contentsOf: eventColors.map { CalendarMarker(color: $0) })
        let remainingSlotsAfterEvents = max(0, 3 - markers.count)
        let reminderColors = reminderProvider.markerColors(for: date, limit: remainingSlotsAfterEvents)
        markers.append(contentsOf: reminderColors.map { CalendarMarker(color: $0) })
        let remainingSlotsAfterReminders = max(0, 3 - markers.count)
        if remainingSlotsAfterReminders > 0,
           !journalStore.entries(on: date, calendar: calendar).isEmpty {
            markers.append(CalendarMarker(color: .indigo))
        }
        return Array(markers.prefix(3))
    }

    func dayBadges(for date: Date, calendar: Calendar) -> [String] {
        var labels: [String] = []
        let year = calendar.component(.year, from: date)

        if calendar.isDate(date, inSameDayAs: dateProvider.now()) {
            labels.append("Today")
        }

        if let birthdayInYear = birthdayDate(in: year, calendar: calendar),
           calendar.isDate(date, inSameDayAs: birthdayInYear) {
            labels.append("Birthday")
        }

        if calendar.isDate(date, inSameDayAs: userData.deathDate) {
            labels.append("End Date")
        }

        return labels
    }

    func birthdayDate(in year: Int, calendar: Calendar) -> Date? {
        let month = calendar.component(.month, from: userData.birthday)
        let day = calendar.component(.day, from: userData.birthday)
        if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
            return date
        }
        if month == 2 && day == 29 {
            return calendar.date(from: DateComponents(year: year, month: 2, day: 28))
        }
        return nil
    }

    func refreshAgenda(for monthStart: Date, calendar: Calendar) {
        let interval = monthInterval(for: monthStart, calendar: calendar)
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
    }

    func performPeriodicRefreshIfNeeded(
        at now: Date,
        monthStart: Date,
        calendar: Calendar,
        force: Bool = false
    ) {
        guard force || isPeriodicRefreshDue(at: now) else { return }
        lastPeriodicRefresh = now
        journalStore.reload()
        refreshAgenda(for: monthStart, calendar: calendar)
    }

    func isPeriodicRefreshDue(at now: Date) -> Bool {
        guard scenePhase == .active, isViewVisible else { return false }
        return now.timeIntervalSince(lastPeriodicRefresh) >= 60
    }

    func monthInterval(for monthStart: Date, calendar: Calendar) -> DateInterval {
        let start = calendar.startOfDay(for: monthStart)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    func agendaItems(
        events: [CalendarEventItem],
        reminders: [ReminderItem],
        journals: [PulseJournalEntry]
    ) -> [AgendaItem] {
        let eventItems = events.map {
            AgendaItem(
                id: "event-\($0.id)",
                kind: .event,
                title: $0.title,
                startDate: $0.startDate,
                endDate: $0.endDate,
                isAllDay: $0.isAllDay,
                color: $0.color
            )
        }
        let reminderItems = reminders.map {
            AgendaItem(
                id: "reminder-\($0.id)",
                kind: .reminder,
                title: $0.title,
                startDate: $0.dueDate,
                endDate: $0.dueDate,
                isAllDay: $0.isAllDay,
                color: $0.color
            )
        }
        let journalItems = journals.map {
            AgendaItem(
                id: "journal-\($0.id.uuidString)",
                kind: .journal,
                title: $0.note,
                startDate: $0.date,
                endDate: $0.date,
                isAllDay: false,
                color: .indigo
            )
        }
        return (eventItems + reminderItems + journalItems).sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate {
                return lhs.startDate < rhs.startDate
            }
            if lhs.isAllDay != rhs.isAllDay {
                return lhs.isAllDay
            }
            if lhs.kind != rhs.kind {
                return kindRank(lhs.kind) < kindRank(rhs.kind)
            }
            return lhs.title < rhs.title
        }
    }

    func kindRank(_ kind: AgendaItem.Kind) -> Int {
        switch kind {
        case .event:
            return 0
        case .reminder:
            return 1
        case .journal:
            return 2
        }
    }
}
