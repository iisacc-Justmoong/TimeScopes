//
//  CalendarView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var userData: UserData

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
        let events = monthEvents(monthStart: monthStart, calendar: calendar)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthHeader(monthStart: monthStart, calendar: calendar)

                    VStack(spacing: 12) {
                        weekdayHeader(symbols: weekdaySymbols)
                        monthGrid(metadata: metadata, calendar: calendar)
                    }
                    .glassCard()

                    dayInsights(for: selectedDate, calendar: calendar)
                        .glassCard()

                    monthHighlights(events: events)
                        .glassCard()
                }
                .padding()
            }
            .glassScreen()
        }
        .onChange(of: displayedMonth) { newValue in
            if !calendar.isDate(selectedDate, equalTo: newValue, toGranularity: .month) {
                selectedDate = newValue
            }
        }
        .onChange(of: selectedDate) { newValue in
            jumpDate = newValue
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
        }
    }

    private func monthHighlights(events: [CalendarEvent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Month Highlights")
                .font(.headline)

            if events.isEmpty {
                Text("No highlights this month.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(events) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.symbol)
                            .foregroundStyle(event.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.callout)
                            Text(event.date, format: .dateTime.year().month().day())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
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
            markers.append(.today)
        }

        if let birthdayInYear = birthdayDate(in: year, calendar: calendar),
           calendar.isDate(date, inSameDayAs: birthdayInYear) {
            markers.append(.birthday)
        }

        if calendar.isDate(date, inSameDayAs: userData.deathDate) {
            markers.append(.end)
        }

        return markers
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

    private func monthEvents(monthStart: Date, calendar: Calendar) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let year = calendar.component(.year, from: monthStart)

        if calendar.isDate(dateProvider.now(), equalTo: monthStart, toGranularity: .month) {
            events.append(CalendarEvent(title: "Today", date: dateProvider.now(), symbol: "circle.fill", color: .accentColor))
        }

        if let birthday = birthdayDate(in: year, calendar: calendar),
           calendar.isDate(birthday, equalTo: monthStart, toGranularity: .month) {
            events.append(CalendarEvent(title: "Birthday", date: birthday, symbol: "gift.fill", color: .pink))
        }

        if calendar.isDate(userData.deathDate, equalTo: monthStart, toGranularity: .month) {
            events.append(CalendarEvent(title: "End Date", date: userData.deathDate, symbol: "flag.fill", color: .orange))
        }

        return events.sorted { $0.date < $1.date }
    }

    private struct MonthMetadata {
        let monthStart: Date
        let daysInMonth: Int
        let leadingEmptyDays: Int
    }

    private struct CalendarEvent: Identifiable {
        let id = UUID()
        let title: String
        let date: Date
        let symbol: String
        let color: Color
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
                        ForEach(markers, id: \.self) { marker in
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

private enum CalendarMarker: CaseIterable {
    case today
    case birthday
    case end

    var color: Color {
        switch self {
        case .today:
            return .accentColor
        case .birthday:
            return .pink
        case .end:
            return .orange
        }
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
}

#Preview {
    CalendarView()
        .environmentObject(UserData())
}
