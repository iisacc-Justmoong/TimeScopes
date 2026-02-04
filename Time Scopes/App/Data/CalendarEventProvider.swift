//
//  CalendarEventProvider.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-04.
//

import EventKit
import Foundation
import SwiftUI
import UIKit

struct CalendarEventItem: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let color: Color
    let calendarTitle: String
}

@MainActor
final class CalendarEventProvider: ObservableObject {
    @Published private(set) var authorizationStatus: EKAuthorizationStatus
    @Published private(set) var events: [CalendarEventItem] = []
    @Published private(set) var hasICloudCalendars: Bool = true

    private let store: EKEventStore
    private let calendar: Calendar
    private var eventsByDay: [Date: [CalendarEventItem]] = [:]

    init(store: EKEventStore = EKEventStore(), calendar: Calendar = .autoupdatingCurrent) {
        self.store = store
        self.calendar = calendar
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    var hasAccess: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        }
        return authorizationStatus == .authorized
    }

    func requestAccessIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { allowed, _ in
                    continuation.resume(returning: allowed)
                }
            }
        }
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if !granted {
            events = []
            eventsByDay = [:]
        }
    }

    func refreshEvents(in interval: DateInterval) {
        guard hasAccess else {
            events = []
            eventsByDay = [:]
            return
        }

        let calendars = iCloudCalendars()
        hasICloudCalendars = !calendars.isEmpty
        guard hasICloudCalendars else {
            events = []
            eventsByDay = [:]
            return
        }
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: calendars)
        let fetched = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        let mapped = fetched.map { event in
            CalendarEventItem(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Untitled",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                color: calendarColor(for: event.calendar),
                calendarTitle: event.calendar.title
            )
        }

        events = mapped
        rebuildEventsByDay()
    }

    func events(on date: Date) -> [CalendarEventItem] {
        eventsByDay[calendar.startOfDay(for: date)] ?? []
    }

    func markerColors(for date: Date, limit: Int) -> [Color] {
        let dayEvents = events(on: date)
        guard !dayEvents.isEmpty else { return [] }
        return dayEvents.prefix(limit).map { $0.color }
    }

    private func rebuildEventsByDay() {
        var grouped: [Date: [CalendarEventItem]] = [:]

        for event in events {
            let startDay = calendar.startOfDay(for: event.startDate)
            let effectiveEnd = event.isAllDay
                ? (calendar.date(byAdding: .second, value: -1, to: event.endDate) ?? event.endDate)
                : event.endDate
            let endDay = calendar.startOfDay(for: effectiveEnd)

            var day = startDay
            while day <= endDay {
                grouped[day, default: []].append(event)
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = nextDay
            }
        }

        for key in grouped.keys {
            grouped[key]?.sort { $0.startDate < $1.startDate }
        }
        eventsByDay = grouped
    }

    private func iCloudCalendars() -> [EKCalendar] {
        let calendars = store.calendars(for: .event)
        return calendars.filter { isICloudSource($0.source) }
    }

    private func isICloudSource(_ source: EKSource) -> Bool {
        guard source.sourceType == .calDAV else {
            return false
        }
        let title = source.title.lowercased()
        if title.contains("icloud") {
            return true
        }
        if title.contains("@icloud.com") || title.contains("@me.com") || title.contains("@mac.com") {
            return true
        }
        return false
    }

    private func calendarColor(for calendar: EKCalendar) -> Color {
        let cgColor = calendar.cgColor ?? UIColor.systemBlue.cgColor
        return Color(UIColor(cgColor: cgColor))
    }
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let dueDate: Date
    let isAllDay: Bool
    let color: Color
    let listTitle: String
}

@MainActor
final class ReminderProvider: ObservableObject {
    @Published private(set) var authorizationStatus: EKAuthorizationStatus
    @Published private(set) var reminders: [ReminderItem] = []
    @Published private(set) var hasICloudReminders: Bool = true

    private let store: EKEventStore
    private let calendar: Calendar
    private var remindersByDay: [Date: [ReminderItem]] = [:]

    init(store: EKEventStore = EKEventStore(), calendar: Calendar = .autoupdatingCurrent) {
        self.store = store
        self.calendar = calendar
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    var hasAccess: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        }
        return authorizationStatus == .authorized
    }

    func requestAccessIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestFullAccessToReminders()) ?? false
        } else {
            granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .reminder) { allowed, _ in
                    continuation.resume(returning: allowed)
                }
            }
        }
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        if !granted {
            reminders = []
            remindersByDay = [:]
        }
    }

    func refreshReminders(in interval: DateInterval) {
        guard hasAccess else {
            reminders = []
            remindersByDay = [:]
            return
        }

        let calendars = iCloudReminderCalendars()
        hasICloudReminders = !calendars.isEmpty
        guard hasICloudReminders else {
            reminders = []
            remindersByDay = [:]
            return
        }

        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: interval.start,
            ending: interval.end,
            calendars: calendars
        )

        store.fetchReminders(matching: predicate) { [weak self] fetched in
            guard let self else { return }
            Task { @MainActor in
                let mapped = (fetched ?? []).compactMap { reminder -> ReminderItem? in
                    guard let components = reminder.dueDateComponents,
                          let dueDate = self.calendar.date(from: components) else {
                        return nil
                    }
                    let isAllDay = components.hour == nil && components.minute == nil && components.second == nil
                    return ReminderItem(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "Untitled",
                        dueDate: dueDate,
                        isAllDay: isAllDay,
                        color: self.listColor(for: reminder.calendar),
                        listTitle: reminder.calendar.title
                    )
                }
                self.reminders = mapped.sorted { $0.dueDate < $1.dueDate }
                self.rebuildRemindersByDay()
            }
        }
    }

    func reminders(on date: Date) -> [ReminderItem] {
        remindersByDay[calendar.startOfDay(for: date)] ?? []
    }

    func markerColors(for date: Date, limit: Int) -> [Color] {
        let dayReminders = reminders(on: date)
        guard !dayReminders.isEmpty else { return [] }
        return dayReminders.prefix(limit).map { $0.color }
    }

    private func rebuildRemindersByDay() {
        var grouped: [Date: [ReminderItem]] = [:]

        for reminder in reminders {
            let day = calendar.startOfDay(for: reminder.dueDate)
            grouped[day, default: []].append(reminder)
        }

        for key in grouped.keys {
            grouped[key]?.sort { $0.dueDate < $1.dueDate }
        }
        remindersByDay = grouped
    }

    private func iCloudReminderCalendars() -> [EKCalendar] {
        let calendars = store.calendars(for: .reminder)
        return calendars.filter { isICloudSource($0.source) }
    }

    private func isICloudSource(_ source: EKSource) -> Bool {
        guard source.sourceType == .calDAV else {
            return false
        }
        let title = source.title.lowercased()
        if title.contains("icloud") {
            return true
        }
        if title.contains("@icloud.com") || title.contains("@me.com") || title.contains("@mac.com") {
            return true
        }
        return false
    }

    private func listColor(for calendar: EKCalendar) -> Color {
        let cgColor = calendar.cgColor ?? UIColor.systemOrange.cgColor
        return Color(UIColor(cgColor: cgColor))
    }
}
