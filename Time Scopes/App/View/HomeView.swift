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
    
    var christmas = AnnualChristmasProperties()
    var annualMondays = AnnualMondayProperties()
    var elapsedDateInThisYear = ElapsedDateInThisYear()
    
    @State var isPresented: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            LeftGradientBackgroundView()
            RightGradientBackgroundView()
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
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
                    EventPlainView(title: "Months", count: monthCount.leftMonths, unit: "")
                    EventPlainView(title: "Weeks", count: weekCount.leftWeeks, unit: "")
                    EventPlainView(title: "Days", count: dayCount.leftDays, unit: "")
                }
                Section(header: Text("You Passed")) {
                    EventPlainView(title: "Months", count: userLivedTime.livedMonths, unit: "")
                    
                    EventPlainView(title: "Weeks", count: userLivedTime.livedDays / 7, unit: "")
                    EventPlainView(title: "Days", count: userLivedTime.livedDays, unit: "")
                    EventPlainView(title: "Hours", count: userLivedTime.livedHours, unit: "")
                    EventPlainView(title: "Minutes", count: userLivedTime.livedMinutes, unit: "")
                    EventPlainView(title: "Seconds", count: userLivedTime.livedSeconds, unit: "")
                }
                // 생일까지 남은 날짜, 다음 N0세 까지 남은 날짜
                Section(header: Text("Your Next events")) {
                    let today = DateUtility.today()
                    let calendar = DateUtility.calendar
                    let nextBirthday = calendar.nextDate(after: today, matching: calendar.dateComponents([.month, .day], from: userData.birthday), matchingPolicy: .nextTimePreservingSmallerComponents) ?? today
                    let daysUntilNextBirthday = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
                    let daysInYear = DateUtility.daysInYear(for: today)
                    
                    let currentAge = userData.age
                    let nextDecade = ((currentAge / 10) + 1) * 10
                    let yearsUntilNextDecade = nextDecade - currentAge
                    EventGaugeView(
                        title: "To Be Age \(nextDecade) :",
                        count: yearsUntilNextDecade,
                        gaugeValue: 10 - yearsUntilNextDecade,
                        min: 0,
                        max: 10,
                        unit: "years"
                    )
                    EventGaugeView(
                        title: "To Next Birthday :",
                        count: daysUntilNextBirthday,
                        gaugeValue: daysInYear - daysUntilNextBirthday,
                        min: 0,
                        max: daysInYear,
                        unit: "days"
                    )
                    EventGaugeView(title: "Remaining Weekdays in Scope",
                                   count: lifeRemainingWorkingTime.remainingWorkingDays,
                                   gaugeValue: userData.age,
                                   min: 0,
                                   max: userData.deathAge,
                                   unit: "days")
                }
                Section(header: Text("Annual Events")) {
                    let daysInYear = DateUtility.daysInYear(for: DateUtility.now())
                    EventGaugeView(title: "This Year",
                                   count: daysInYear - elapsedDateInThisYear.daysElapsedThisYear,
                                   gaugeValue: elapsedDateInThisYear.daysElapsedThisYear,
                                   min: 0,
                                   max: daysInYear,
                                   unit: "days"
                    )
                    EventPlainView(title: christmas.name,
                                   count: christmas.count,
                                   unit: "days"
                    )
                    EventPlainView(title: annualMondays.name,
                                   count: annualMondays.count,
                                   unit: "times"
                    )
                }
            }
        }
        .background(Color.clear)
        .scrollContentBackground(.hidden)

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
