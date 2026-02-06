//
//  CalendarView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var userData: UserData
    @StateObject var eventProvider = CalendarEventProvider()
    @StateObject var reminderProvider = ReminderProvider()
    @StateObject var journalStore = PulseJournalStore()

    @State var displayedMonth: Date
    @State var selectedDate: Date
    @State var jumpDate: Date
    @State var isJumpPresented = false
    @State var jumpSheetHeight: CGFloat = 520

    let dateProvider: DateProviding
    let ageCalculator: AgeCalculating

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
        let weekdaySymbols = weekdaySymbols(for: calendar)
        let events = eventProvider.events
        let reminders = reminderProvider.reminders

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthHeader(monthStart: monthStart, calendar: calendar)
                    calendarGrid(monthStart: monthStart, weekdaySymbols: weekdaySymbols, calendar: calendar)
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
}

#Preview {
    CalendarView()
        .environmentObject(UserData())
}
