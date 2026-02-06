//
//  ContentView.swift
//  Regret Vaccine
//
//  Created by 윤무영 on 9/26/24.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var userData: UserData
    @EnvironmentObject var userLivedTime: UserLivedTime
    
    @EnvironmentObject var monthCount: MonthCount
    @EnvironmentObject var weekCount: WeekCount
    @EnvironmentObject var dayCount: DayCount
    
    @ObservedObject var lifeRemainingWorkingTime: LifeRemainingWorkingTime
    @StateObject private var weekdayTicker = SecondTicker()
    @StateObject private var eventProvider = CalendarEventProvider()
    @StateObject private var reminderProvider = ReminderProvider()
    @EnvironmentObject private var locationPermission: LocationPermissionManager
    private let widgetStore = WidgetSnapshotStore()
    @State private var lastWidgetSync: Date = .distantPast

    private let dateProvider: DateProviding
    private let nextEventCalculator: NextEventCalculating
    private let livedTimeCalculator: LivedTimeCalculating

    private var christmas: AnnualChristmasProperties {
        AnnualChristmasProperties(dateProvider: dateProvider)
    }

    private var annualMondays: AnnualMondayProperties {
        AnnualMondayProperties(dateProvider: dateProvider)
    }

    private var elapsedDateInThisYear: ElapsedDateInThisYear {
        ElapsedDateInThisYear(dateProvider: dateProvider)
    }
    
    @State var isPresented: Bool = false

    init(
        lifeRemainingWorkingTime: LifeRemainingWorkingTime,
        dateProvider: DateProviding = SystemDateProvider(),
        nextEventCalculator: NextEventCalculating = NextEventCalculator(),
        livedTimeCalculator: LivedTimeCalculating = LivedTimeCalculator()
    ) {
        self.lifeRemainingWorkingTime = lifeRemainingWorkingTime
        self.dateProvider = dateProvider
        self.nextEventCalculator = nextEventCalculator
        self.livedTimeCalculator = livedTimeCalculator
    }
    
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: dateProvider.now(), by: 1)) { timeline in
                List {
                    Section(header: Text("Profile")) {
                        UserProfileView()
                            .sheet(isPresented: $isPresented) {
                                InputView()
                                    .environmentObject(userData)
                                    .interactiveDismissDisabled(true)
                            }
                            .onTapGesture {
                                isPresented = true
                            }
                            .glassRow()
                        NavigationLink {
                            TimeScopeHeatmapDetailView(unit: .month)
                        } label: {
                            EventPlainView(title: "Months Left", count: monthCount.leftMonths, unit: "")
                        }
                        .glassRow()
                        NavigationLink {
                            TimeScopeHeatmapDetailView(unit: .week)
                        } label: {
                            EventPlainView(title: "Weeks Left", count: weekCount.leftWeeks, unit: "")
                        }
                        .glassRow()
                        NavigationLink {
                            TimeScopeHeatmapDetailView(unit: .day)
                        } label: {
                            EventPlainView(title: "Days Left", count: dayCount.leftDays, unit: "")
                        }
                        .glassRow()
                    }
                    Section(header: Text("Elapsed Time")) {
                        let livedTime = livedTimeCalculator.livedTime(from: userData.birthday, to: timeline.date)
                        EventPlainView(title: "Months Lived", count: livedTime.months, unit: "")
                            .glassRow()
                        EventPlainView(title: "Weeks Lived", count: livedTime.days / 7, unit: "")
                            .glassRow()
                        EventPlainView(title: "Days Lived", count: livedTime.days, unit: "")
                            .glassRow()
                        EventPlainView(title: "Hours Lived", count: livedTime.hours, unit: "")
                            .glassRow()
                        EventPlainView(title: "Minutes Lived", count: livedTime.minutes, unit: "")
                            .glassRow()
                        EventPlainView(title: "Seconds Lived", count: livedTime.seconds, unit: "")
                            .glassRow()
                    }
                    // 생일까지 남은 날짜, 다음 N0세 까지 남은 날짜
                Section(header: Text("Upcoming Milestones")) {
                    let nextBirthdayStats = nextEventCalculator.nextBirthdayStats(from: userData.birthday)
                    let nextDecadeStats = nextEventCalculator.nextDecadeStats(from: userData.age)
                    let now = dateProvider.now()
                    let nextDecadeDate = dateProvider.calendar.date(byAdding: .year, value: nextDecadeStats.nextDecade, to: userData.birthday) ?? now
                    let secondsToNextDecade = max(0, Int(nextDecadeDate.timeIntervalSince(now)))
                    let minutesToNextDecade = secondsToNextDecade / 60
                    let hoursToNextDecade = secondsToNextDecade / 3_600
                    let daysToNextDecade = secondsToNextDecade / 86_400
                    let weeksToNextDecade = daysToNextDecade / 7
                    let monthsToNextDecade = daysToNextDecade / 30
                    NavigationLink {
                        EventDetailView(
                            title: "Until Age \(nextDecadeStats.nextDecade)",
                            count: nextDecadeStats.yearsUntilNextDecade,
                            unit: "years",
                            gauge: EventDetailView.GaugeData(value: 10 - nextDecadeStats.yearsUntilNextDecade, min: 0, max: 10),
                            breakdown: [
                                EventDetailView.BreakdownItem(label: "Months", value: monthsToNextDecade, unit: "months"),
                                EventDetailView.BreakdownItem(label: "Weeks", value: weeksToNextDecade, unit: "weeks"),
                                EventDetailView.BreakdownItem(label: "Days", value: daysToNextDecade, unit: "days"),
                                EventDetailView.BreakdownItem(label: "Hours", value: hoursToNextDecade, unit: "hours"),
                                EventDetailView.BreakdownItem(label: "Minutes", value: minutesToNextDecade, unit: "minutes"),
                                EventDetailView.BreakdownItem(label: "Seconds", value: secondsToNextDecade, unit: "seconds")
                            ]
                        )
                    } label: {
                        EventGaugeView(
                            title: "Until Age \(nextDecadeStats.nextDecade)",
                            count: nextDecadeStats.yearsUntilNextDecade,
                                gaugeValue: 10 - nextDecadeStats.yearsUntilNextDecade,
                                min: 0,
                                max: 10,
                                unit: "years"
                            )
                        }
                    .glassRow()
                    NavigationLink {
                        let nextBirthdayDate = dateProvider.calendar.nextDate(
                            after: now,
                            matching: dateProvider.calendar.dateComponents([.month, .day], from: userData.birthday),
                            matchingPolicy: .nextTimePreservingSmallerComponents
                        ) ?? now
                        let secondsToNextBirthday = max(0, Int(nextBirthdayDate.timeIntervalSince(now)))
                        let minutesToNextBirthday = secondsToNextBirthday / 60
                        let hoursToNextBirthday = secondsToNextBirthday / 3_600
                        let daysToNextBirthday = secondsToNextBirthday / 86_400
                        EventDetailView(
                            title: "Until Next Birthday",
                            count: nextBirthdayStats.daysUntilNextBirthday,
                            unit: "days",
                            gauge: EventDetailView.GaugeData(
                                value: nextBirthdayStats.daysInYear - nextBirthdayStats.daysUntilNextBirthday,
                                min: 0,
                                max: nextBirthdayStats.daysInYear
                            ),
                            breakdown: [
                                EventDetailView.BreakdownItem(label: "Hours", value: hoursToNextBirthday, unit: "hours"),
                                EventDetailView.BreakdownItem(label: "Minutes", value: minutesToNextBirthday, unit: "minutes"),
                                EventDetailView.BreakdownItem(label: "Seconds", value: secondsToNextBirthday, unit: "seconds")
                            ]
                        )
                    } label: {
                        EventGaugeView(
                            title: "Until Next Birthday",
                            count: nextBirthdayStats.daysUntilNextBirthday,
                                gaugeValue: nextBirthdayStats.daysInYear - nextBirthdayStats.daysUntilNextBirthday,
                                min: 0,
                                max: nextBirthdayStats.daysInYear,
                                unit: "days"
                            )
                        }
                    .glassRow()
                        NavigationLink {
                            let totalWeekdays = lifeRemainingWorkingTime.remainingWorkingDays
                            EventDetailView(
                                title: "Weekdays Remaining",
                                count: totalWeekdays,
                                unit: "days",
                                gauge: EventDetailView.GaugeData(value: userData.age, min: 0, max: userData.deathAge),
                                extraContent: {
                                    WeekdayScopeDetailContent(
                                        totalWeekdays: totalWeekdays,
                                        ticker: weekdayTicker
                                    )
                                        .environmentObject(userData)
                                }
                            )
                        } label: {
                            EventGaugeView(
                                title: "Weekdays Remaining",
                                count: lifeRemainingWorkingTime.remainingWorkingDays,
                                gaugeValue: userData.age,
                                min: 0,
                                max: userData.deathAge,
                                unit: "days"
                            )
                        }
                        .glassRow()
                    }
                    Section(header: Text("Annual Highlights")) {
                        let daysInYear = dateProvider.daysInYear(for: dateProvider.now())
                        NavigationLink {
                            ThisYearDetailView(dateProvider: dateProvider)
                        } label: {
                            EventGaugeView(
                                title: "Year Remaining",
                                count: daysInYear - elapsedDateInThisYear.daysElapsedThisYear,
                                gaugeValue: elapsedDateInThisYear.daysElapsedThisYear,
                                min: 0,
                                max: daysInYear,
                                unit: "days"
                            )
                        }
                        .glassRow()
                        NavigationLink {
                            NextChristmasDetailView(dateProvider: dateProvider)
                        } label: {
                            EventPlainView(title: christmas.name, count: christmas.count, unit: "days")
                        }
                        .glassRow()
                        NavigationLink {
                            RemainingMondaysDetailView(dateProvider: dateProvider)
                        } label: {
                            EventPlainView(title: annualMondays.name, count: annualMondays.count, unit: "times")
                        }
                        .glassRow()
                    }
                    Section(header: Text("Daily Summary")) {
                        let now = dateProvider.now()
                        let calendar = dateProvider.calendar
                        let startOfToday = calendar.startOfDay(for: now)
                        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
                        let dayInterval = DateInterval(start: startOfToday, end: endOfToday)
                        let nextHour = calendar.nextDate(
                            after: now,
                            matching: DateComponents(minute: 0, second: 0),
                            matchingPolicy: .nextTimePreservingSmallerComponents
                        ) ?? endOfToday
                        let remainingToNextHourSeconds = max(0, Int(nextHour.timeIntervalSince(now)))
                        let nextHourText = formatMS(remainingToNextHourSeconds)
                        let eventSeconds = Int(eventProvider.events(on: startOfToday).reduce(0.0) { total, event in
                            total + clampedDuration(for: event, in: dayInterval)
                        })
                        let reminderSeconds = Int(reminderProvider.reminders(on: startOfToday).reduce(0.0) { total, reminder in
                            total + reminderDuration(for: reminder, in: dayInterval)
                        })
                        let totalDaySeconds = 24 * 3_600
                        let remainingSeconds = max(0, Int(endOfToday.timeIntervalSince(now)))
                        let remainingText = formatHMS(remainingSeconds)
                        let remainingPercent = percentText(value: remainingSeconds, total: totalDaySeconds)
                        let sunGauge = sunGaugeData(for: now)

                        let workHours = max(0, min(userData.workHoursPerDay, 24))
                        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
                        let baseScheduledSeconds = min(24, workHours + sleepHours) * 3_600
                        let scheduledSeconds = min(totalDaySeconds, baseScheduledSeconds + eventSeconds + reminderSeconds)
                        let freeSeconds = max(0, totalDaySeconds - scheduledSeconds)

                        DailyEventGaugeRow(
                            title: "Until Next Hour",
                            valueText: nextHourText,
                            percentText: percentText(value: remainingToNextHourSeconds, total: 3_600),
                            gaugeValue: Double(remainingToNextHourSeconds),
                            gaugeMax: 3_600
                        )
                        .glassRow()

                        DailyEventGaugeRow(
                            title: sunGauge.title,
                            valueText: sunGauge.valueText,
                            percentText: sunGauge.percentText,
                            gaugeValue: sunGauge.value,
                            gaugeMax: sunGauge.max
                        )
                        .glassRow()

                        DailyEventGaugeRow(
                            title: "Time Left Today",
                            valueText: remainingText,
                            percentText: remainingPercent,
                            gaugeValue: Double(remainingSeconds),
                            gaugeMax: Double(totalDaySeconds)
                        )
                        .glassRow()

                        DailyEventGaugeRow(
                            title: "Free Time (Work + Sleep + Timed Items)",
                            valueText: formatHMS(freeSeconds),
                            percentText: percentText(value: freeSeconds, total: totalDaySeconds),
                            gaugeValue: Double(freeSeconds),
                            gaugeMax: Double(totalDaySeconds)
                        )
                        .glassRow()

                        DailyEventGaugeRow(
                            title: "Allocated Time (Work + Sleep + Timed Items)",
                            valueText: formatHMS(scheduledSeconds),
                            percentText: percentText(value: scheduledSeconds, total: totalDaySeconds),
                            gaugeValue: Double(scheduledSeconds),
                            gaugeMax: Double(totalDaySeconds)
                        )
                        .glassRow()
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
                .background(GlassScreenBackground())
            }
        }
        .task {
            await eventProvider.requestAccessIfNeeded()
            await reminderProvider.requestAccessIfNeeded()
            refreshDailyAgenda(for: dateProvider.now())
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshDailyAgenda(for: dateProvider.now())
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onReceive(weekdayTicker.$now) { now in
            syncWidgetSnapshotIfNeeded(at: now)
        }
        .onReceive(eventProvider.$events) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onReceive(reminderProvider.$reminders) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onReceive(locationPermission.$location) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onChange(of: userData.name) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onChange(of: userData.birthday) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onChange(of: userData.deathDate) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onChange(of: userData.workHoursPerDay) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onChange(of: userData.sleepHoursPerDay) { _ in
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .onAppear {
            syncWidgetSnapshotIfNeeded(at: dateProvider.now(), force: true)
        }
        .glassScreen()
    }

    private func refreshDailyAgenda(for date: Date) {
        let interval = dayInterval(for: date)
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let calendar = dateProvider.calendar
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    private func clampedDuration(for event: CalendarEventItem, in interval: DateInterval) -> TimeInterval {
        let start = max(event.startDate, interval.start)
        let end = min(event.endDate, interval.end)
        return max(0, end.timeIntervalSince(start))
    }

    private func reminderDuration(for reminder: ReminderItem, in interval: DateInterval) -> TimeInterval {
        guard let startDate = reminder.startDate else { return 0 }
        let start = max(startDate, interval.start)
        let end = min(reminder.dueDate, interval.end)
        guard end > start else { return 0 }
        return end.timeIntervalSince(start)
    }

    private func sunGaugeData(for date: Date) -> SunGaugeData {
        guard let location = locationPermission.location,
              let window = SunEventCalculator.nextEventWindow(
                for: date,
                location: location,
                calendar: dateProvider.calendar,
                timeZone: dateProvider.calendar.timeZone
              ) else {
            return SunGaugeData(
                title: "Until Sunrise/Sunset",
                valueText: "Location required",
                percentText: "0%",
                value: 0,
                max: 1
            )
        }

        let remaining = max(0, Int(window.nextDate.timeIntervalSince(date)))
        let segment = max(1, Int(window.nextDate.timeIntervalSince(window.previousDate)))
        let title = window.nextEvent == .sunrise ? "Until Sunrise" : "Until Sunset"

        return SunGaugeData(
            title: title,
            valueText: formatHMS(remaining),
            percentText: percentText(value: remaining, total: segment),
            value: Double(remaining),
            max: Double(segment)
        )
    }

    private func syncWidgetSnapshotIfNeeded(at now: Date, force: Bool = false) {
        let interval: TimeInterval = 30
        guard force || now.timeIntervalSince(lastWidgetSync) >= interval else { return }
        lastWidgetSync = now
        widgetStore.saveSnapshot(buildWidgetSnapshot(at: now))
    }

    private func buildWidgetSnapshot(at now: Date) -> WidgetSnapshot {
        let profile = WidgetSnapshot.Profile(
            name: userData.name,
            age: userData.age,
            monthsLeft: monthCount.leftMonths,
            weeksLeft: weekCount.leftWeeks,
            daysLeft: dayCount.leftDays
        )

        let livedTime = livedTimeCalculator.livedTime(from: userData.birthday, to: now)
        let elapsed = WidgetSnapshot.Elapsed(
            months: livedTime.months,
            weeks: livedTime.days / 7,
            days: livedTime.days,
            hours: livedTime.hours,
            minutes: livedTime.minutes,
            seconds: livedTime.seconds
        )

        let nextBirthdayStats = nextEventCalculator.nextBirthdayStats(from: userData.birthday)
        let nextDecadeStats = nextEventCalculator.nextDecadeStats(from: userData.age)
        let milestones = WidgetSnapshot.Milestones(
            nextDecadeAge: nextDecadeStats.nextDecade,
            yearsUntilNextDecade: nextDecadeStats.yearsUntilNextDecade,
            daysUntilNextBirthday: nextBirthdayStats.daysUntilNextBirthday,
            weekdaysRemaining: lifeRemainingWorkingTime.remainingWorkingDays
        )

        let daysInYear = dateProvider.daysInYear(for: now)
        let highlights = WidgetSnapshot.Highlights(
            yearRemainingDays: daysInYear - elapsedDateInThisYear.daysElapsedThisYear,
            nextChristmasDays: christmas.count,
            remainingMondays: annualMondays.count
        )

        let calendar = dateProvider.calendar
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        let dayInterval = DateInterval(start: startOfToday, end: endOfToday)
        let nextHour = calendar.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? endOfToday
        let remainingToNextHourSeconds = max(0, Int(nextHour.timeIntervalSince(now)))
        let nextHourText = formatMS(remainingToNextHourSeconds)
        let nextHourPercent = percentText(value: remainingToNextHourSeconds, total: 3_600)

        let eventSeconds = Int(eventProvider.events(on: startOfToday).reduce(0.0) { total, event in
            total + clampedDuration(for: event, in: dayInterval)
        })
        let reminderSeconds = Int(reminderProvider.reminders(on: startOfToday).reduce(0.0) { total, reminder in
            total + reminderDuration(for: reminder, in: dayInterval)
        })
        let totalDaySeconds = 24 * 3_600
        let remainingSeconds = max(0, Int(endOfToday.timeIntervalSince(now)))
        let remainingText = formatHMS(remainingSeconds)
        let remainingPercent = percentText(value: remainingSeconds, total: totalDaySeconds)
        let sunGauge = sunGaugeData(for: now)

        let workHours = max(0, min(userData.workHoursPerDay, 24))
        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
        let baseScheduledSeconds = min(24, workHours + sleepHours) * 3_600
        let scheduledSeconds = min(totalDaySeconds, baseScheduledSeconds + eventSeconds + reminderSeconds)
        let freeSeconds = max(0, totalDaySeconds - scheduledSeconds)

        let daily = WidgetSnapshot.DailySummary(
            nextHourText: nextHourText,
            nextHourPercent: nextHourPercent,
            sunTitle: sunGauge.title,
            sunValueText: sunGauge.valueText,
            sunPercentText: sunGauge.percentText,
            timeLeftText: remainingText,
            timeLeftPercent: remainingPercent,
            freeTimeText: formatHMS(freeSeconds),
            freeTimePercent: percentText(value: freeSeconds, total: totalDaySeconds),
            allocatedTimeText: formatHMS(scheduledSeconds),
            allocatedTimePercent: percentText(value: scheduledSeconds, total: totalDaySeconds)
        )

        return WidgetSnapshot(
            updatedAt: now,
            profile: profile,
            elapsed: elapsed,
            milestones: milestones,
            highlights: highlights,
            daily: daily
        )
    }
}

private struct SunGaugeData {
    let title: String
    let valueText: String
    let percentText: String
    let value: Double
    let max: Double
}

private func formatHMS(_ totalSeconds: Int) -> String {
    let clamped = max(0, totalSeconds)
    let hours = clamped / 3_600
    let minutes = (clamped % 3_600) / 60
    let seconds = clamped % 60
    return "\(hours)h \(minutes)m \(seconds)s"
}

private func formatMS(_ totalSeconds: Int) -> String {
    let clamped = max(0, totalSeconds)
    let minutes = clamped / 60
    let seconds = clamped % 60
    return "\(minutes)m \(seconds)s"
}

private func percentText(value: Int, total: Int) -> String {
    guard total > 0 else { return "0%" }
    let percent = (Double(value) / Double(total)) * 100
    return String(format: "%.0f%%", percent)
}

private struct DailyEventGaugeRow: View {
    let title: String
    let valueText: String
    let percentText: String
    let gaugeValue: Double
    let gaugeMax: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.callout)
                Spacer()
                Text(valueText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                Text(percentText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Gauge(value: gaugeValue, in: 0...max(1, gaugeMax)) {
                Text(percentText)
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .foregroundStyle(Color.accentColor)
            .tint(Color.accentColor)
            .labelsHidden()
        }
    }
}

private struct WeekdayScopeDetailContent: View {
    @EnvironmentObject var userData: UserData
    let totalWeekdays: Int
    @ObservedObject var ticker: SecondTicker
    @State private var remainingWorkSeconds: Int = 0
    @State private var remainingWorkSleepSeconds: Int = 0
    @State private var lastTick: Date = Date()

    var body: some View {
        let weeksEquivalent = totalWeekdays / 5
        let monthsEquivalent = totalWeekdays / 21
        let workHours = max(0, min(userData.workHoursPerDay, 24))
        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
        let freeWorkMinutes = remainingWorkSeconds / 60
        let freeWorkHours = remainingWorkSeconds / 3_600

        let freeWorkSleepMinutes = remainingWorkSleepSeconds / 60
        let freeWorkSleepHours = remainingWorkSleepSeconds / 3_600

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekday Conversions")
                    .font(.headline)
                WeekdayDetailRow(title: "Weeks (weekdays)", value: weeksEquivalent, unit: "weeks")
                WeekdayDetailRow(title: "Months (weekdays)", value: monthsEquivalent, unit: "months")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Free Time (Weekdays, Work \(workHours)h)")
                    .font(.headline)
                WeekdayDetailRow(title: "Hours", value: freeWorkHours, unit: "hours")
                WeekdayDetailRow(title: "Minutes", value: freeWorkMinutes, unit: "minutes")
                WeekdayDetailRow(title: "Seconds", value: remainingWorkSeconds, unit: "seconds")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Free Time (Weekdays, Work \(workHours)h + Sleep \(sleepHours)h)")
                    .font(.headline)
                WeekdayDetailRow(title: "Hours", value: freeWorkSleepHours, unit: "hours")
                WeekdayDetailRow(title: "Minutes", value: freeWorkSleepMinutes, unit: "minutes")
                WeekdayDetailRow(title: "Seconds", value: remainingWorkSleepSeconds, unit: "seconds")
            }
        }
        .onChange(of: userData.workHoursPerDay) { _ in
            resetCountdown(at: ticker.now)
        }
        .onChange(of: userData.sleepHoursPerDay) { _ in
            resetCountdown(at: ticker.now)
        }
        .onChange(of: userData.deathDate) { _ in
            resetCountdown(at: ticker.now)
        }
        .onAppear {
            resetCountdown(at: ticker.now)
        }
        .onReceive(ticker.$now) { updated in
            let delta = max(0, Int(updated.timeIntervalSince(lastTick).rounded(.down)))
            guard delta > 0 else { return }
            remainingWorkSeconds = max(0, remainingWorkSeconds - delta)
            remainingWorkSleepSeconds = max(0, remainingWorkSleepSeconds - delta)
            lastTick = updated
        }
    }

    private func resetCountdown(at date: Date) {
        let workHours = max(0, min(userData.workHoursPerDay, 24))
        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
        let freeWorkHoursPerDay = max(0, 24 - workHours)
        let freeWorkSleepHoursPerDay = max(0, 24 - workHours - sleepHours)

        remainingWorkSeconds = Int(ceil(remainingFreeSeconds(
            from: date,
            to: userData.deathDate,
            freeHoursPerDay: freeWorkHoursPerDay
        )))
        remainingWorkSleepSeconds = Int(ceil(remainingFreeSeconds(
            from: date,
            to: userData.deathDate,
            freeHoursPerDay: freeWorkSleepHoursPerDay
        )))
        lastTick = date
    }

    private func remainingFreeSeconds(from now: Date, to endDate: Date, freeHoursPerDay: Int) -> TimeInterval {
        guard freeHoursPerDay > 0 else { return 0 }
        let calendar = Calendar.autoupdatingCurrent
        let dayInterval = calendar.dateInterval(of: .day, for: now)
        let startDay = calendar.startOfDay(for: now)
        let endDay = calendar.startOfDay(for: endDate)
        guard endDay >= startDay else { return 0 }

        let totalWeekdays = weekdaysBetween(startDay: startDay, endDay: endDay, calendar: calendar)
        let todayIsWeekday = isWeekday(startDay, calendar: calendar)
        let fullFutureWeekdays = max(0, totalWeekdays - (todayIsWeekday ? 1 : 0))

        let dayEnd = dayInterval?.end ?? calendar.date(byAdding: .day, value: 1, to: startDay) ?? startDay
        let endBoundary = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        let effectiveDayEnd = min(dayEnd, endBoundary)
        let remainingSecondsToday = max(0, effectiveDayEnd.timeIntervalSince(now))
        let dayDuration = max(1, dayInterval?.duration ?? 86_400)
        let remainingFractionToday = min(1, remainingSecondsToday / dayDuration)

        let todayFreeSeconds = todayIsWeekday
            ? Double(freeHoursPerDay * 3_600) * remainingFractionToday
            : 0

        let fullDaysSeconds = fullFutureWeekdays * freeHoursPerDay * 3_600
        return max(0, todayFreeSeconds + Double(fullDaysSeconds))
    }


    private func weekdaysBetween(startDay: Date, endDay: Date, calendar: Calendar) -> Int {
        let daysBetween = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        let totalDays = daysBetween + 1
        guard totalDays > 0 else { return 0 }

        let fullWeeks = totalDays / 7
        var weekdays = fullWeeks * 5
        let remainingDays = totalDays % 7
        if remainingDays > 0 {
            let startWeekday = calendar.component(.weekday, from: startDay) // 1 = Sunday
            for offset in 0..<remainingDays {
                let weekday = ((startWeekday - 1 + offset) % 7) + 1
                if weekday >= 2 && weekday <= 6 {
                    weekdays += 1
                }
            }
        }
        return weekdays
    }

    private func isWeekday(_ date: Date, calendar: Calendar) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday >= 2 && weekday <= 6
    }
}

private struct WeekdayDetailRow: View {
    let title: String
    let value: Int
    let unit: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
            Spacer()
            Text("\(value) \(unit)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
        }
    }
}


#Preview {
    HomeView(lifeRemainingWorkingTime: LifeRemainingWorkingTime(userLivedTime: UserLivedTime(model: UserData())))
        .environmentObject(UserData())
        .environmentObject(UserLivedTime(model: UserData()))
        .environmentObject(MonthCount(viewModel: UserData()))
        .environmentObject(WeekCount(viewModel: UserData()))
        .environmentObject(DayCount(viewModel: UserData()))
}
