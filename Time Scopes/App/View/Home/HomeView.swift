//
//  HomeView.swift
//  Time Scopes
//
//  Created by 윤무영 on 9/26/24.
//

import SwiftUI

enum HomeScrollTarget: String {
    case profileAge
    case profileMonthsLeft
    case profileWeeksLeft
    case profileDaysLeft
    case elapsedMonths
    case elapsedWeeks
    case elapsedDays
    case elapsedHours
    case elapsedMinutes
    case elapsedSeconds
    case milestoneNextDecade
    case milestoneNextBirthday
    case milestoneWeekdaysRemaining
    case highlightsYearRemaining
    case highlightsNextChristmas
    case highlightsRemainingMondays
    case dailyNextHour
    case dailySun
    case dailyTimeLeft
    case dailyFreeTime
    case dailyAllocatedTime
}

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var monthCount: MonthCount
    @EnvironmentObject var weekCount: WeekCount
    @EnvironmentObject var dayCount: DayCount
    @EnvironmentObject var deepLinkCenter: AppDeepLinkCenter

    @ObservedObject var lifeRemainingWorkingTime: LifeRemainingWorkingTime
    @StateObject var weekdayTicker = SecondTicker()
    @StateObject var eventProvider = CalendarEventProvider()
    @StateObject var reminderProvider = ReminderProvider()
    @EnvironmentObject var locationPermission: LocationPermissionManager
    let widgetStore = WidgetSnapshotStore()
    @State var lastWidgetSync: Date = .distantPast

    let dateProvider: DateProviding
    let nextEventCalculator: NextEventCalculating
    let livedTimeCalculator: LivedTimeCalculating

    var christmas: AnnualChristmasProperties {
        AnnualChristmasProperties(dateProvider: dateProvider)
    }

    var annualMondays: AnnualMondayProperties {
        AnnualMondayProperties(dateProvider: dateProvider)
    }

    var elapsedDateInThisYear: ElapsedDateInThisYear {
        ElapsedDateInThisYear(dateProvider: dateProvider)
    }

    @State var isPresented = false

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
            ScrollViewReader { proxy in
                TimelineView(.periodic(from: dateProvider.now(), by: 1)) { timeline in
                    List {
                        profileSection()
                        elapsedSection(at: timeline.date)
                        upcomingMilestonesSection(at: timeline.date)
                        annualHighlightsSection()
                        dailySummarySection(at: timeline.date)
                    }
                    .scrollContentBackground(.hidden)
                    .listRowSeparator(.hidden)
                    .background(GlassScreenBackground())
                    .onAppear {
                        scrollToDeepLinkIfNeeded(using: proxy)
                    }
                    .onChange(of: deepLinkCenter.route?.id) { _ in
                        scrollToDeepLinkIfNeeded(using: proxy)
                    }
                }
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
}

#Preview {
    HomeView(lifeRemainingWorkingTime: LifeRemainingWorkingTime(userLivedTime: UserLivedTime(model: UserData())))
        .environmentObject(UserData())
        .environmentObject(UserLivedTime(model: UserData()))
        .environmentObject(MonthCount(viewModel: UserData()))
        .environmentObject(WeekCount(viewModel: UserData()))
        .environmentObject(DayCount(viewModel: UserData()))
        .environmentObject(AppDeepLinkCenter())
}
