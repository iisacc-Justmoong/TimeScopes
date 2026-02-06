//
//  CalendarView+Layout.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

extension CalendarView {
    func monthHeader(monthStart: Date, calendar: Calendar) -> some View {
        HStack(spacing: 12) {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 4) {
                Text(monthTitle(monthStart))
                    .font(.title2)
                    .fontWeight(.semibold)
                HStack(spacing: 12) {
                    Button("Today") {
                        let now = dateProvider.now()
                        displayedMonth = now
                        selectedDate = now
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)

                    Button {
                        isJumpPresented = true
                    } label: {
                        Label("Jump", systemImage: "calendar.badge.clock")
                            .labelStyle(.titleAndIcon)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .buttonStyle(.plain)
        }
    }

    func calendarGrid(monthStart: Date, weekdaySymbols: [String], calendar: Calendar) -> some View {
        VStack(spacing: 12) {
            weekdayHeader(symbols: weekdaySymbols)
            monthGrid(monthStart: monthStart, calendar: calendar)
        }
        .glassCard(showBorder: false)
    }

    func weekdayHeader(symbols: [String]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func monthGrid(monthStart: Date, calendar: Calendar) -> some View {
        let metadata = monthMetadata(for: monthStart, calendar: calendar)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        let leadingPlaceholders = (0..<metadata.leadingEmptyDays).map { -($0 + 1) }
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(leadingPlaceholders, id: \.self) { _ in
                Color.clear
                    .frame(height: 36)
            }
            ForEach(1...metadata.daysInMonth, id: \.self) { day in
                let date = calendar.date(byAdding: .day, value: day - 1, to: metadata.monthStart) ?? metadata.monthStart
                CalendarDayCell(
                    day: day,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDate(date, inSameDayAs: dateProvider.now()),
                    markers: markers(for: date, calendar: calendar)
                ) {
                    selectedDate = date
                }
            }
        }
    }

    func dayInsights(for date: Date, calendar: Calendar) -> some View {
        let today = dateProvider.startOfDay(for: dateProvider.now())
        let selectedDay = dateProvider.startOfDay(for: date)
        let daysFromToday = calendar.dateComponents([.day], from: today, to: selectedDay).day ?? 0
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let ageOnDate = ageCalculator.age(birthday: userData.birthday, now: date)
        let ageLabel = ageOnDate < 0 ? "Before birth" : "\(ageOnDate) yrs"
        let badges = dayBadges(for: date, calendar: calendar)
        let dayEvents = eventProvider.events(on: date)
        let dayReminders = reminderProvider.allReminders(on: date)
        let dayJournals = journalStore.entries(on: date, calendar: calendar)
        let agendaItems = agendaItems(events: dayEvents, reminders: dayReminders, journals: dayJournals)

        return VStack(alignment: .leading, spacing: 12) {
            Text(fullDateTitle(date))
                .font(.headline)

            if !badges.isEmpty {
                HStack(spacing: 8) {
                    ForEach(badges, id: \.self) { badge in
                        Text(badge)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    }
                }
            }

            HStack {
                InsightRow(title: "Day of year", value: "\(dayOfYear)")
                InsightRow(title: "Week", value: "\(weekOfYear)")
            }
            HStack {
                InsightRow(title: "From today", value: formatSigned(daysFromToday) + " days")
                InsightRow(title: "Age", value: ageLabel)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Agenda")
                    .font(.headline)
                if agendaItems.isEmpty {
                    Text("No events or reminders.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(agendaItems) { item in
                        AgendaItemRow(item: item)
                    }
                }

                if !eventProvider.hasAccess {
                    Text("Calendar access not granted.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if !eventProvider.hasCalendars {
                    Text("No calendars found.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if !reminderProvider.hasAccess {
                    Text("Reminders access not granted.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if !reminderProvider.hasReminderLists {
                    Text("No reminder lists found.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.top, 4)
        }
    }

    func monthHighlights(events: [CalendarEventItem], reminders: [ReminderItem]) -> some View {
        let calendar = dateProvider.calendar
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        let interval = monthInterval(for: monthStart, calendar: calendar)
        let monthJournals = journalStore.entries.filter { interval.contains($0.date) }
        let agendaItems = agendaItems(events: events, reminders: reminders, journals: monthJournals)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Agenda This Month")
                .font(.headline)

            if agendaItems.isEmpty {
                Text("No events or reminders this month.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(agendaItems) { item in
                    AgendaMonthRow(item: item)
                }
            }

            if !eventProvider.hasAccess {
                Text("Calendar access not granted.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else if !eventProvider.hasCalendars {
                Text("No calendars found.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            if !reminderProvider.hasAccess {
                Text("Reminders access not granted.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else if !reminderProvider.hasReminderLists {
                Text("No reminder lists found.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    func monthTitle(_ date: Date) -> String {
        CalendarView.monthFormatter.string(from: date)
    }

    func fullDateTitle(_ date: Date) -> String {
        CalendarView.fullDateFormatter.string(from: date)
    }

    func formatSigned(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
