//
//  CalendarView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var eventProvider = CalendarEventProvider()
    @StateObject private var reminderProvider = ReminderProvider()
    @StateObject private var journalStore = PulseJournalStore()

    @State private var displayedMonth: Date
    @State private var selectedDate: Date
    @State private var jumpDate: Date
    @State private var isJumpPresented = false
    @State private var jumpSheetHeight: CGFloat = 520

    private let dateProvider: DateProviding
    private let ageCalculator: AgeCalculating

    init(
        dateProvider: DateProviding = SystemDateProvider(),
        ageCalculator: AgeCalculating = AgeCalculator()
    ) {
        self.dateProvider = dateProvider
        self.ageCalculator = ageCalculator
        let now = dateProvider.now()
        _displayedMonth = State(initialValue: now)
        _selectedDate = State(initialValue: now)
        _jumpDate = State(initialValue: now)
    }

    var body: some View {
        let calendar = dateProvider.calendar
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        let metadata = monthMetadata(for: monthStart, calendar: calendar)
        let weekdaySymbols = weekdaySymbols(for: calendar)
        let events = eventProvider.events
        let reminders = reminderProvider.reminders

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthHeader(monthStart: monthStart, calendar: calendar)

                    VStack(spacing: 12) {
                        weekdayHeader(symbols: weekdaySymbols)
                        monthGrid(metadata: metadata, calendar: calendar)
                    }
                    .glassCard(showBorder: false)

                    dayInsights(for: selectedDate, calendar: calendar)
                        .glassCard(showBorder: false)

                    monthHighlights(events: events, reminders: reminders)
                        .glassCard(showBorder: false)
                }
                .padding()
            }
            .glassScreen()
        }
        .onChange(of: displayedMonth) { newValue in
            if !calendar.isDate(selectedDate, equalTo: newValue, toGranularity: .month) {
                selectedDate = newValue
            }
            let newMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) ?? newValue
            refreshAgenda(for: newMonthStart, calendar: calendar)
        }
        .onChange(of: selectedDate) { newValue in
            jumpDate = newValue
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            refreshAgenda(for: monthStart, calendar: calendar)
        }
        .sheet(isPresented: $isJumpPresented) {
            JumpDatePicker(
                jumpDate: $jumpDate,
                sheetHeight: $jumpSheetHeight,
                onDone: { isJumpPresented = false }
            )
            .onChange(of: jumpDate) { newValue in
                displayedMonth = newValue
                selectedDate = newValue
            }
            .presentationDetents([.height(jumpSheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    private func monthHeader(monthStart: Date, calendar: Calendar) -> some View {
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

    private func weekdayHeader(symbols: [String]) -> some View {
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

    private func monthGrid(metadata: MonthMetadata, calendar: Calendar) -> some View {
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

    private func dayInsights(for date: Date, calendar: Calendar) -> some View {
        let today = dateProvider.startOfDay(for: dateProvider.now())
        let selectedDay = dateProvider.startOfDay(for: date)
        let daysFromToday = calendar.dateComponents([.day], from: today, to: selectedDay).day ?? 0
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let ageOnDate = ageCalculator.age(birthday: userData.birthday, now: date)
        let ageLabel = ageOnDate < 0 ? "Before birth" : "\(ageOnDate) yrs"
        let badges = dayBadges(for: date, calendar: calendar)
        let dayEvents = eventProvider.events(on: date)
        let dayReminders = reminderProvider.reminders(on: date)
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
                } else if !eventProvider.hasICloudCalendars {
                    Text("No iCloud calendars found. Move events into an iCloud calendar in Apple Calendar.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if !reminderProvider.hasAccess {
                    Text("Reminders access not granted.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if !reminderProvider.hasICloudReminders {
                    Text("No iCloud reminder lists found. Use an iCloud list in Reminders.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.top, 4)
        }
    }

    private func monthHighlights(events: [CalendarEventItem], reminders: [ReminderItem]) -> some View {
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
            } else if !eventProvider.hasICloudCalendars {
                Text("No iCloud calendars found. Move events into an iCloud calendar in Apple Calendar.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            if !reminderProvider.hasAccess {
                Text("Reminders access not granted.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else if !reminderProvider.hasICloudReminders {
                Text("No iCloud reminder lists found. Use an iCloud list in Reminders.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private func monthTitle(_ date: Date) -> String {
        CalendarView.monthFormatter.string(from: date)
    }

    private func fullDateTitle(_ date: Date) -> String {
        CalendarView.fullDateFormatter.string(from: date)
    }

    private func formatSigned(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func weekdaySymbols(for calendar: Calendar) -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    private func monthMetadata(for monthStart: Date, calendar: Calendar) -> MonthMetadata {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        return MonthMetadata(monthStart: monthStart, daysInMonth: daysInMonth, leadingEmptyDays: leadingEmptyDays)
    }

    private func markers(for date: Date, calendar: Calendar) -> [CalendarMarker] {
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

    private func dayBadges(for date: Date, calendar: Calendar) -> [String] {
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

    private func birthdayDate(in year: Int, calendar: Calendar) -> Date? {
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

    private struct MonthMetadata {
        let monthStart: Date
        let daysInMonth: Int
        let leadingEmptyDays: Int
    }

}

private struct CalendarDayCell: View {
    let day: Int
    let isSelected: Bool
    let isToday: Bool
    let markers: [CalendarMarker]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(day)")
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                if !markers.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(markers) { marker in
                            Circle()
                                .fill(marker.color)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday ? Color.accentColor.opacity(0.7) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct InsightRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct JumpDatePicker: View {
    @Binding var jumpDate: Date
    @Binding var sheetHeight: CGFloat
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Go to Date")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    onDone()
                }
                .font(.callout)
            }

            DatePicker(
                "Go to Date",
                selection: $jumpDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
        .padding()
        .background(Color.clear)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SheetHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(SheetHeightKey.self) { value in
            let clamped = max(360, value)
            if abs(sheetHeight - clamped) > 1 {
                sheetHeight = clamped
            }
        }
    }
}

private enum SheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CalendarMarker: Identifiable {
    let id = UUID()
    let color: Color
}

private struct CalendarEventRow: View {
    let event: CalendarEventItem

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(event.color)
                .frame(width: 8, height: 8)
            Text(event.title)
                .font(.callout)
            Spacer()
            Text(timeLabel(for: event))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func timeLabel(for event: CalendarEventItem) -> String {
        if event.isAllDay {
            return "All day"
        }
        let formatter = CalendarView.timeFormatter
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

private struct AgendaItem: Identifiable {
    enum Kind {
        case event
        case reminder
        case journal
    }

    let id: String
    let kind: Kind
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let color: Color
}

private struct AgendaItemRow: View {
    let item: AgendaItem

    var body: some View {
        HStack(spacing: 8) {
            if item.kind == .reminder {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(item.color)
            } else if item.kind == .journal {
                Image(systemName: "note.text")
                    .foregroundStyle(item.color)
            } else {
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
            }
            Text(item.title)
                .font(.callout)
            Spacer()
            Text(timeLabel(for: item))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func timeLabel(for item: AgendaItem) -> String {
        if item.isAllDay {
            return "All day"
        }
        let formatter = CalendarView.timeFormatter
        if item.kind == .reminder || item.kind == .journal {
            return formatter.string(from: item.startDate)
        }
        return "\(formatter.string(from: item.startDate)) - \(formatter.string(from: item.endDate))"
    }
}

private struct AgendaMonthRow: View {
    let item: AgendaItem

    var body: some View {
        HStack(spacing: 12) {
            if item.kind == .reminder {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(item.color)
            } else if item.kind == .journal {
                Image(systemName: "note.text")
                    .foregroundStyle(item.color)
            } else {
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.callout)
                Text(item.startDate, format: .dateTime.year().month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !item.isAllDay {
                    Text(timeRange(for: item))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private func timeRange(for item: AgendaItem) -> String {
        let formatter = CalendarView.timeFormatter
        if item.kind == .reminder || item.kind == .journal {
            return formatter.string(from: item.startDate)
        }
        return "\(formatter.string(from: item.startDate)) - \(formatter.string(from: item.endDate))"
    }
}

private extension CalendarView {
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private extension CalendarView {
    func refreshAgenda(for monthStart: Date, calendar: Calendar) {
        let interval = monthInterval(for: monthStart, calendar: calendar)
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
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

#Preview {
    CalendarView()
        .environmentObject(UserData())
}
