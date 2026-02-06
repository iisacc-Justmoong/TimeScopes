import SwiftUI
import UIKit
import XCTest
@testable import Time_Scopes

@MainActor
final class ViewRenderingCoverageTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    func testPulseComponentsRender() {
        render(PulseSectionHeader(title: "Pulse", subtitle: "Subtitle"))
        render(PulseSummaryCell(title: "Peak", value: "Mon 3h"))
        render(PulseWeeklyEventRow(event: PulseWeeklyEvent(day: "Mon", title: "Deep Work", duration: 5_400)))
        render(WeeklyRhythmChart(days: sampleIntensities(), highlightDay: "Wed"))
        render(PulseDayLineChart(values: sampleSeries(), maxValue: 5, currentFraction: 0.42))
        render(
            PulsePrescriptionRow(
                prescription: PulsePrescription(
                    focus: "Load",
                    title: "Shift one block",
                    detail: "Move one task from Wed to Fri.",
                    impact: "90m"
                )
            )
        )
        render(PulseTag(text: "Focus"))
        render(PulseCallout(title: "Pattern", detail: "Wednesday remains the busiest day."))
        render(
            PulseJournalRow(
                entry: PulseJournalEntry(
                    id: UUID(),
                    date: TestDateFactory.date("2026-02-06 13:45:00"),
                    note: "Closed two deep tasks and deferred one low-value meeting."
                ),
                onEdit: {},
                onDelete: {}
            )
        )
        render(
            PulseJournalComposer(
                title: "New Entry",
                saveLabel: "Save",
                prompt: "What was your highest leverage action today?",
                draft: .constant("Captured one meaningful decision."),
                onSave: { _ in }
            )
        )
    }

    func testPulseSectionsBuildAndRender() {
        render(
            PulseView()
                .environmentObject(AppDeepLinkCenter())
                .environmentObject(makeUserData())
        )
    }

    func testCalendarAndHomeComponentsRender() {
        render(
            CalendarDayCell(
                day: 12,
                isSelected: true,
                isToday: true,
                markers: [CalendarMarker(color: .blue), CalendarMarker(color: .orange)],
                overflowCount: 2,
                action: {}
            )
        )
        render(
            CalendarDayCell(
                day: 24,
                isSelected: false,
                isToday: false,
                markers: [],
                overflowCount: 0,
                action: {}
            )
        )
        render(InsightRow(title: "Longest Session", value: "2h 30m"))
        render(
            JumpDatePicker(
                jumpDate: .constant(TestDateFactory.date("2026-02-06 00:00:00")),
                sheetHeight: .constant(520),
                onDone: {}
            )
        )
        render(AgendaItemRow(item: makeAgendaItem(kind: .event, allDay: false)))
        render(AgendaItemRow(item: makeAgendaItem(kind: .reminder, allDay: false)))
        render(AgendaItemRow(item: makeAgendaItem(kind: .journal, allDay: false)))
        render(AgendaMonthRow(item: makeAgendaItem(kind: .event, allDay: true)))
        render(AgendaMonthRow(item: makeAgendaItem(kind: .reminder, allDay: false)))
        render(AgendaMonthRow(item: makeAgendaItem(kind: .journal, allDay: false)))
        render(
            DailyEventGaugeRow(
                title: "Scheduled",
                valueText: "6h 15m",
                percentText: "26%",
                gaugeValue: 22_500,
                gaugeMax: 86_400
            )
        )
        render(WeekdayDetailRow(title: "Weeks", value: 540, unit: "weeks"))
    }

    func testInputAndWeekdayScopeViewsRender() {
        let userData = makeUserData()
        render(InputView().environmentObject(userData))
        render(
            WeekdayScopeDetailContent(
                totalWeekdays: 320,
                ticker: SecondTicker()
            )
            .environmentObject(userData)
        )
    }

    private func render<V: View>(_ view: V, size: CGSize = CGSize(width: 390, height: 844)) {
        let hostingController = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = hostingController
        window.isHidden = false
        hostingController.view.frame = window.bounds
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        self.window?.isHidden = true
        self.window = window
    }

    private func sampleSeries() -> [Double] {
        [0, 0, 1, 2, 1, 0, 0, 2, 3, 4, 3, 2, 2, 3, 2, 1, 2, 4, 3, 2, 1, 0, 0, 0]
    }

    private func sampleIntensities() -> [PulseDayIntensity] {
        [
            PulseDayIntensity(day: "Mon", intensity: 0.5),
            PulseDayIntensity(day: "Tue", intensity: 0.7),
            PulseDayIntensity(day: "Wed", intensity: 1.0),
            PulseDayIntensity(day: "Thu", intensity: 0.6),
            PulseDayIntensity(day: "Fri", intensity: 0.4),
            PulseDayIntensity(day: "Sat", intensity: 0.2),
            PulseDayIntensity(day: "Sun", intensity: 0.3)
        ]
    }

    private func makeAgendaItem(kind: AgendaItem.Kind, allDay: Bool) -> AgendaItem {
        AgendaItem(
            id: "\(kind)-\(allDay)",
            kind: kind,
            title: "Agenda Item",
            startDate: TestDateFactory.date("2026-02-06 10:00:00"),
            endDate: TestDateFactory.date("2026-02-06 11:00:00"),
            isAllDay: allDay,
            color: .indigo
        )
    }

    private func makeUserData() -> UserData {
        let userData = UserData(store: InMemoryUserProfileStore())
        userData.name = "Tester"
        userData.birthday = TestDateFactory.date("1995-01-01 00:00:00")
        userData.deathDate = TestDateFactory.date("2085-01-01 00:00:00")
        userData.workHoursPerDay = 8
        userData.sleepHoursPerDay = 7
        return userData
    }
}
