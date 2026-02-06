//
//  HomeView+Sections.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

extension HomeView {
    @ViewBuilder
    func profileSection() -> some View {
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
                .id(HomeScrollTarget.profileAge)
                .glassRow()
            NavigationLink {
                TimeScopeHeatmapDetailView(unit: .month)
            } label: {
                EventPlainView(title: "Months Left", count: monthCount.leftMonths, unit: "")
            }
            .id(HomeScrollTarget.profileMonthsLeft)
            .glassRow()
            NavigationLink {
                TimeScopeHeatmapDetailView(unit: .week)
            } label: {
                EventPlainView(title: "Weeks Left", count: weekCount.leftWeeks, unit: "")
            }
            .id(HomeScrollTarget.profileWeeksLeft)
            .glassRow()
            NavigationLink {
                TimeScopeHeatmapDetailView(unit: .day)
            } label: {
                EventPlainView(title: "Days Left", count: dayCount.leftDays, unit: "")
            }
            .id(HomeScrollTarget.profileDaysLeft)
            .glassRow()
        }
    }

    @ViewBuilder
    func elapsedSection(at date: Date) -> some View {
        Section(header: Text("Elapsed Time")) {
            let livedTime = livedTimeCalculator.livedTime(from: userData.birthday, to: date)
            EventPlainView(title: "Months Lived", count: livedTime.months, unit: "")
                .id(HomeScrollTarget.elapsedMonths)
                .glassRow()
            EventPlainView(title: "Weeks Lived", count: livedTime.days / 7, unit: "")
                .id(HomeScrollTarget.elapsedWeeks)
                .glassRow()
            EventPlainView(title: "Days Lived", count: livedTime.days, unit: "")
                .id(HomeScrollTarget.elapsedDays)
                .glassRow()
            EventPlainView(title: "Hours Lived", count: livedTime.hours, unit: "")
                .id(HomeScrollTarget.elapsedHours)
                .glassRow()
            EventPlainView(title: "Minutes Lived", count: livedTime.minutes, unit: "")
                .id(HomeScrollTarget.elapsedMinutes)
                .glassRow()
            EventPlainView(title: "Seconds Lived", count: livedTime.seconds, unit: "")
                .id(HomeScrollTarget.elapsedSeconds)
                .glassRow()
        }
    }

    @ViewBuilder
    func upcomingMilestonesSection(at now: Date) -> some View {
        Section(header: Text("Upcoming Milestones")) {
            let nextBirthdayStats = nextEventCalculator.nextBirthdayStats(from: userData.birthday)
            let nextDecadeStats = nextEventCalculator.nextDecadeStats(from: userData.age)
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
            .id(HomeScrollTarget.milestoneNextDecade)
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
            .id(HomeScrollTarget.milestoneNextBirthday)
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
            .id(HomeScrollTarget.milestoneWeekdaysRemaining)
            .glassRow()
        }
    }

    @ViewBuilder
    func annualHighlightsSection() -> some View {
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
            .id(HomeScrollTarget.highlightsYearRemaining)
            .glassRow()
            NavigationLink {
                NextChristmasDetailView(dateProvider: dateProvider)
            } label: {
                EventPlainView(title: christmas.name, count: christmas.count, unit: "days")
            }
            .id(HomeScrollTarget.highlightsNextChristmas)
            .glassRow()
            NavigationLink {
                RemainingMondaysDetailView(dateProvider: dateProvider)
            } label: {
                EventPlainView(title: annualMondays.name, count: annualMondays.count, unit: "times")
            }
            .id(HomeScrollTarget.highlightsRemainingMondays)
            .glassRow()
        }
    }

    @ViewBuilder
    func dailySummarySection(at now: Date) -> some View {
        Section(header: Text("Daily Summary")) {
            let summary = dailySummary(at: now)
            DailyEventGaugeRow(
                title: summary.nextHour.title,
                valueText: summary.nextHour.valueText,
                percentText: summary.nextHour.percentText,
                gaugeValue: summary.nextHour.value,
                gaugeMax: summary.nextHour.max
            )
            .id(HomeScrollTarget.dailyNextHour)
            .glassRow()

            DailyEventGaugeRow(
                title: summary.sun.title,
                valueText: summary.sun.valueText,
                percentText: summary.sun.percentText,
                gaugeValue: summary.sun.value,
                gaugeMax: summary.sun.max
            )
            .id(HomeScrollTarget.dailySun)
            .glassRow()

            DailyEventGaugeRow(
                title: summary.timeLeft.title,
                valueText: summary.timeLeft.valueText,
                percentText: summary.timeLeft.percentText,
                gaugeValue: summary.timeLeft.value,
                gaugeMax: summary.timeLeft.max
            )
            .id(HomeScrollTarget.dailyTimeLeft)
            .glassRow()

            DailyEventGaugeRow(
                title: summary.freeTime.title,
                valueText: summary.freeTime.valueText,
                percentText: summary.freeTime.percentText,
                gaugeValue: summary.freeTime.value,
                gaugeMax: summary.freeTime.max
            )
            .id(HomeScrollTarget.dailyFreeTime)
            .glassRow()

            DailyEventGaugeRow(
                title: summary.allocatedTime.title,
                valueText: summary.allocatedTime.valueText,
                percentText: summary.allocatedTime.percentText,
                gaugeValue: summary.allocatedTime.value,
                gaugeMax: summary.allocatedTime.max
            )
            .id(HomeScrollTarget.dailyAllocatedTime)
            .glassRow()
        }
    }
}
