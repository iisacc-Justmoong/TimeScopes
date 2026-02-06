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
                    Section(header: Text("About You")) {
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
                            EventPlainView(title: "Months", count: monthCount.leftMonths, unit: "")
                        }
                        .glassRow()
                        NavigationLink {
                            TimeScopeHeatmapDetailView(unit: .week)
                        } label: {
                            EventPlainView(title: "Weeks", count: weekCount.leftWeeks, unit: "")
                        }
                        .glassRow()
                        NavigationLink {
                            TimeScopeHeatmapDetailView(unit: .day)
                        } label: {
                            EventPlainView(title: "Days", count: dayCount.leftDays, unit: "")
                        }
                        .glassRow()
                    }
                    Section(header: Text("Passed Time")) {
                        let livedTime = livedTimeCalculator.livedTime(from: userData.birthday, to: timeline.date)
                        EventPlainView(title: "Months", count: livedTime.months, unit: "")
                            .glassRow()
                        EventPlainView(title: "Weeks", count: livedTime.days / 7, unit: "")
                            .glassRow()
                        EventPlainView(title: "Days", count: livedTime.days, unit: "")
                            .glassRow()
                        EventPlainView(title: "Hours", count: livedTime.hours, unit: "")
                            .glassRow()
                        EventPlainView(title: "Minutes", count: livedTime.minutes, unit: "")
                            .glassRow()
                        EventPlainView(title: "Seconds", count: livedTime.seconds, unit: "")
                            .glassRow()
                    }
                    // 생일까지 남은 날짜, 다음 N0세 까지 남은 날짜
                Section(header: Text("In Your Life")) {
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
                            title: "To Be Age \(nextDecadeStats.nextDecade)",
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
                            title: "To Be Age \(nextDecadeStats.nextDecade) :",
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
                            title: "To Next Birthday",
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
                            title: "To Next Birthday :",
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
                                title: "Remaining Weekdays in Scope",
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
                                title: "Remaining Weekdays in Scope",
                                count: lifeRemainingWorkingTime.remainingWorkingDays,
                                gaugeValue: userData.age,
                                min: 0,
                                max: userData.deathAge,
                                unit: "days"
                            )
                        }
                        .glassRow()
                    }
                    Section(header: Text("Annual Events")) {
                        let daysInYear = dateProvider.daysInYear(for: dateProvider.now())
                        NavigationLink {
                            ThisYearDetailView(dateProvider: dateProvider)
                        } label: {
                            EventGaugeView(
                                title: "This Year",
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
                }
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
                .background(GlassScreenBackground())
            }
        }
        .glassScreen()
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
                Text("Conversions")
                    .font(.headline)
                WeekdayDetailRow(title: "Weeks (weekday)", value: weeksEquivalent, unit: "weeks")
                WeekdayDetailRow(title: "Months (weekday)", value: monthsEquivalent, unit: "months")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Free Time (Work \(workHours)h)")
                    .font(.headline)
                WeekdayDetailRow(title: "Hours", value: freeWorkHours, unit: "hours")
                WeekdayDetailRow(title: "Minutes", value: freeWorkMinutes, unit: "minutes")
                WeekdayDetailRow(title: "Seconds", value: remainingWorkSeconds, unit: "seconds")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Free Time (Work \(workHours)h + Sleep \(sleepHours)h)")
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
