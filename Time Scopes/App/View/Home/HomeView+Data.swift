//
//  HomeView+Data.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation

extension HomeView {
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
        let nextHour = calendar.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? endOfToday
        let remainingToNextHourSeconds = max(0, Int(nextHour.timeIntervalSince(now)))
        let elapsedToNextHourSeconds = max(0, 3_600 - remainingToNextHourSeconds)
        let nextHourText = HomeFormatting.formatMS(remainingToNextHourSeconds)
        let nextHourPercent = HomeFormatting.percentText(value: elapsedToNextHourSeconds, total: 3_600)

        let eventSeconds = Int(eventProvider.events(on: startOfToday).reduce(0.0) { total, event in
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
        let interval: TimeInterval = 30
        guard force || now.timeIntervalSince(lastWidgetSync) >= interval else { return }
        lastWidgetSync = now
        widgetStore.saveSnapshot(buildWidgetSnapshot(at: now))
    }

    func buildWidgetSnapshot(at now: Date) -> WidgetSnapshot {
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
            pulse: .empty
        )
    }
}
