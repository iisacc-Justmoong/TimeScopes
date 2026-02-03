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
    
    private let dateProvider: DateProviding
    private let nextEventCalculator: NextEventCalculating

    var christmas: AnnualChristmasProperties
    var annualMondays: AnnualMondayProperties
    var elapsedDateInThisYear: ElapsedDateInThisYear
    
    @State var isPresented: Bool = false

    init(
        lifeRemainingWorkingTime: LifeRemainingWorkingTime,
        dateProvider: DateProviding = SystemDateProvider(),
        nextEventCalculator: NextEventCalculating = NextEventCalculator()
    ) {
        self.lifeRemainingWorkingTime = lifeRemainingWorkingTime
        self.dateProvider = dateProvider
        self.nextEventCalculator = nextEventCalculator
        self.christmas = AnnualChristmasProperties(dateProvider: dateProvider)
        self.annualMondays = AnnualMondayProperties(dateProvider: dateProvider)
        self.elapsedDateInThisYear = ElapsedDateInThisYear(dateProvider: dateProvider)
    }
    
    var body: some View {
        NavigationStack {
            List {
                    Section(header: EmptyView()) {
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
                    Section(header: EmptyView()) {
                        EventPlainView(title: "Months", count: userLivedTime.livedTime.months, unit: "")
                            .glassRow()
                        EventPlainView(title: "Weeks", count: userLivedTime.livedTime.days / 7, unit: "")
                            .glassRow()
                        EventPlainView(title: "Days", count: userLivedTime.livedTime.days, unit: "")
                            .glassRow()
                        EventPlainView(title: "Hours", count: userLivedTime.livedTime.hours, unit: "")
                            .glassRow()
                        EventPlainView(title: "Minutes", count: userLivedTime.livedTime.minutes, unit: "")
                            .glassRow()
                        EventPlainView(title: "Seconds", count: userLivedTime.livedTime.seconds, unit: "")
                            .glassRow()
                    }
                    // 생일까지 남은 날짜, 다음 N0세 까지 남은 날짜
                Section(header: EmptyView()) {
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
                            EventDetailView(
                                title: "Remaining Weekdays in Scope",
                                count: lifeRemainingWorkingTime.remainingWorkingDays,
                                unit: "days",
                                gauge: EventDetailView.GaugeData(value: userData.age, min: 0, max: userData.deathAge)
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
                    Section(header: EmptyView()) {
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
        .glassScreen()
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
