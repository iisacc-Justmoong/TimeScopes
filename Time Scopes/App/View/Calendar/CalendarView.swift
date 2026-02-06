//
//  CalendarView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var userData: UserData
    @StateObject var eventProvider = CalendarEventProvider()
    @StateObject var reminderProvider = ReminderProvider()
    @StateObject var journalStore = PulseJournalStore()
    @StateObject var refreshTicker = SecondTicker()

    @State var displayedMonth: Date
    @State var selectedDate: Date
    @State var jumpDate: Date
    @State var isJumpPresented = false
    @State var jumpSheetHeight: CGFloat = 520
    @State var isViewVisible = false
    @State var lastPeriodicRefresh: Date = .distantPast

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
        let month = monthInterval(for: monthStart, calendar: calendar)
        let weekdaySymbols = weekdaySymbols(for: calendar)
        let events = eventProvider.events
        let reminders = reminderProvider.allReminders.filter { reminder in
            if let startDate = reminder.startDate {
                return reminder.dueDate > month.start && startDate < month.end
            }
            return month.contains(reminder.dueDate)
        }

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
        .onChange(of: displayedMonth) { _, newValue in
            if !calendar.isDate(selectedDate, equalTo: newValue, toGranularity: .month) {
                selectedDate = newValue
            }
            let newMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) ?? newValue
            refreshAgenda(for: newMonthStart, calendar: calendar)
        }
        .onChange(of: selectedDate) { _, newValue in
            jumpDate = newValue
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            performPeriodicRefreshIfNeeded(
                at: dateProvider.now(),
                monthStart: monthStart,
                calendar: calendar,
                force: true
            )
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            performPeriodicRefreshIfNeeded(
                at: dateProvider.now(),
                monthStart: monthStart,
                calendar: calendar,
                force: true
            )
        }
        .onReceive(refreshTicker.$now) { now in
            performPeriodicRefreshIfNeeded(
                at: now,
                monthStart: monthStart,
                calendar: calendar
            )
        }
        .onAppear {
            isViewVisible = true
            performPeriodicRefreshIfNeeded(
                at: dateProvider.now(),
                monthStart: monthStart,
                calendar: calendar,
                force: true
            )
        }
        .onDisappear {
            isViewVisible = false
        }
        .sheet(isPresented: $isJumpPresented) {
            JumpDatePicker(
                jumpDate: $jumpDate,
                sheetHeight: $jumpSheetHeight,
                onDone: { isJumpPresented = false }
            )
            .onChange(of: jumpDate) { _, newValue in
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
