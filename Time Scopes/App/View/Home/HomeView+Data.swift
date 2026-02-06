//
//  HomeView+Data.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation
import SwiftUI

extension HomeView {
    func scrollTarget(for route: AppDeepLink) -> HomeScrollTarget? {
        guard route.tab == .home else { return nil }
        switch route.section {
        case "profile":
            switch route.item {
            case "monthsLeft":
                return .profileMonthsLeft
            case "weeksLeft":
                return .profileWeeksLeft
            case "daysLeft":
                return .profileDaysLeft
            default:
                return .profileAge
            }
        case "elapsed":
            switch route.item {
            case "months":
                return .elapsedMonths
            case "weeks":
                return .elapsedWeeks
            case "days":
                return .elapsedDays
            case "hours":
                return .elapsedHours
            case "minutes":
                return .elapsedMinutes
            case "seconds":
                return .elapsedSeconds
            default:
                return .elapsedDays
            }
        case "milestones":
            switch route.item {
            case "yearsUntilNextDecade":
                return .milestoneNextDecade
            case "daysUntilNextBirthday":
                return .milestoneNextBirthday
            case "weekdaysRemaining":
                return .milestoneWeekdaysRemaining
            default:
                return .milestoneNextDecade
            }
        case "highlights":
            switch route.item {
            case "yearRemaining":
                return .highlightsYearRemaining
            case "nextChristmas":
                return .highlightsNextChristmas
            case "remainingMondays":
                return .highlightsRemainingMondays
            default:
                return .highlightsYearRemaining
            }
        case "daily":
            switch route.item {
            case "nextHour":
                return .dailyNextHour
            case "sun":
                return .dailySun
            case "timeLeft":
                return .dailyTimeLeft
            case "freeTime":
                return .dailyFreeTime
            case "allocatedTime":
                return .dailyAllocatedTime
            default:
                return .dailyTimeLeft
            }
        default:
            return nil
        }
    }

    func scrollToDeepLinkIfNeeded(using proxy: ScrollViewProxy) {
        guard let route = deepLinkCenter.route,
              let target = scrollTarget(for: route) else {
            return
        }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }

    func performPeriodicRefreshIfNeeded(at now: Date, force: Bool = false) {
        guard force || isPeriodicRefreshDue(at: now) else { return }
        lastPeriodicRefresh = now
        locationPermission.refreshStatus()
        refreshDailyAgenda(for: now)
        syncWidgetSnapshotIfNeeded(at: now, force: true)
    }

    func isPeriodicRefreshDue(at now: Date) -> Bool {
        guard scenePhase == .active, isViewVisible else { return false }
        return now.timeIntervalSince(lastPeriodicRefresh) >= 60
    }

    func refreshDailyAgenda(for date: Date) {
        let interval = dayInterval(for: date)
        eventProvider.refreshEvents(in: interval)
        reminderProvider.refreshReminders(in: interval)
    }

    func dayInterval(for date: Date) -> DateInterval {
        let calendar = dateProvider.calendar
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    func clampedDuration(for event: CalendarEventItem, in interval: DateInterval) -> TimeInterval {
        let start = max(event.startDate, interval.start)
        let end = min(event.endDate, interval.end)
        return max(0, end.timeIntervalSince(start))
    }

    func reminderDuration(for reminder: ReminderItem, in interval: DateInterval) -> TimeInterval {
        guard let startDate = reminder.startDate else { return 0 }
        let start = max(startDate, interval.start)
        let end = min(reminder.dueDate, interval.end)
        guard end > start else { return 0 }
        return end.timeIntervalSince(start)
    }

    func sunGaugeData(for date: Date) -> HomeGaugeData {
        guard let location = locationPermission.location,
              let window = SunEventCalculator.nextEventWindow(
                for: date,
                location: location,
                calendar: dateProvider.calendar,
                timeZone: dateProvider.calendar.timeZone
              ) else {
            return HomeGaugeData(
                title: "Until Sunrise/Sunset",
                valueText: "Location required",
                percentText: "0%",
                value: 0,
                max: 1
            )
        }

        let remaining = max(0, Int(window.nextDate.timeIntervalSince(date)))
        let segment = max(1, Int(window.nextDate.timeIntervalSince(window.previousDate)))
        let elapsed = max(0, segment - remaining)
        let title = window.nextEvent == .sunrise ? "Until Sunrise" : "Until Sunset"

        return HomeGaugeData(
            title: title,
            valueText: HomeFormatting.formatHMS(remaining),
            percentText: HomeFormatting.percentText(value: elapsed, total: segment),
            value: Double(elapsed),
            max: Double(segment)
        )
    }

    func dailySummary(at now: Date) -> HomeDailySummary {
        let calendar = dateProvider.calendar
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        let dayInterval = DateInterval(start: startOfToday, end: endOfToday)
        let nextHourDate = calendar.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? endOfToday
        let remainingToNextHourSeconds = max(0, Int(nextHourDate.timeIntervalSince(now)))
        let elapsedToNextHourSeconds = max(0, 3_600 - remainingToNextHourSeconds)
        let nextHourText = HomeFormatting.formatMS(remainingToNextHourSeconds)
        let nextHourPercent = HomeFormatting.percentText(value: elapsedToNextHourSeconds, total: 3_600)

        let eventSeconds = Int(eventProvider.events(on: startOfToday).filter { !$0.isAllDay }.reduce(0.0) { total, event in
            total + clampedDuration(for: event, in: dayInterval)
        })
        let reminderSeconds = Int(reminderProvider.reminders(on: startOfToday).reduce(0.0) { total, reminder in
            total + reminderDuration(for: reminder, in: dayInterval)
        })

        let totalDaySeconds = 24 * 3_600
        let remainingSeconds = max(0, Int(endOfToday.timeIntervalSince(now)))
        let remainingText = HomeFormatting.formatHMS(remainingSeconds)
        let elapsedSeconds = max(0, totalDaySeconds - remainingSeconds)
        let timeProgressPercent = HomeFormatting.percentText(value: elapsedSeconds, total: totalDaySeconds)
        let sunGauge = sunGaugeData(for: now)

        let workHours = max(0, min(userData.workHoursPerDay, 24))
        let sleepHours = max(0, min(userData.sleepHoursPerDay, 24))
        let baseScheduledSeconds = min(24, workHours + sleepHours) * 3_600
        let scheduledSeconds = min(totalDaySeconds, baseScheduledSeconds + eventSeconds + reminderSeconds)
        let freeSeconds = max(0, totalDaySeconds - scheduledSeconds)

        let nextHour = HomeGaugeData(
            title: "Until Next Hour",
            valueText: nextHourText,
            percentText: nextHourPercent,
            value: Double(elapsedToNextHourSeconds),
            max: 3_600
        )

        let timeLeft = HomeGaugeData(
            title: "Time Left Today",
            valueText: remainingText,
            percentText: timeProgressPercent,
            value: Double(elapsedSeconds),
            max: Double(totalDaySeconds)
        )

        let freeTime = HomeGaugeData(
            title: "Free Time (Work + Sleep + Timed Items)",
            valueText: HomeFormatting.formatHMS(freeSeconds),
            percentText: HomeFormatting.percentText(value: freeSeconds, total: totalDaySeconds),
            value: Double(freeSeconds),
            max: Double(totalDaySeconds)
        )

        let allocatedTime = HomeGaugeData(
            title: "Allocated Time (Work + Sleep + Timed Items)",
            valueText: HomeFormatting.formatHMS(scheduledSeconds),
            percentText: HomeFormatting.percentText(value: scheduledSeconds, total: totalDaySeconds),
            value: Double(scheduledSeconds),
            max: Double(totalDaySeconds)
        )

        return HomeDailySummary(
            nextHour: nextHour,
            sun: sunGauge,
            timeLeft: timeLeft,
            freeTime: freeTime,
            allocatedTime: allocatedTime
        )
    }

    func syncWidgetSnapshotIfNeeded(at now: Date, force: Bool = false) {
        let interval: TimeInterval = 120
        guard force || now.timeIntervalSince(lastWidgetSync) >= interval else { return }
        lastWidgetSync = now
        widgetStore.updateSnapshot(requestTimelineReload: force) { current in
            buildWidgetSnapshot(at: now, pulse: current.pulse)
        }
    }

    func buildWidgetSnapshot(at now: Date, pulse: WidgetSnapshot.Pulse) -> WidgetSnapshot {
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

        let summary = dailySummary(at: now)
        let daily = WidgetSnapshot.DailySummary(
            nextHourText: summary.nextHour.valueText,
            nextHourPercent: summary.nextHour.percentText,
            sunTitle: summary.sun.title,
            sunValueText: summary.sun.valueText,
            sunPercentText: summary.sun.percentText,
            timeLeftText: summary.timeLeft.valueText,
            timeLeftPercent: summary.timeLeft.percentText,
            freeTimeText: summary.freeTime.valueText,
            freeTimePercent: summary.freeTime.percentText,
            allocatedTimeText: summary.allocatedTime.valueText,
            allocatedTimePercent: summary.allocatedTime.percentText
        )

        return WidgetSnapshot(
            updatedAt: now,
            profile: profile,
            elapsed: elapsed,
            milestones: milestones,
            highlights: highlights,
            daily: daily,
            pulse: pulse
        )
    }
}
