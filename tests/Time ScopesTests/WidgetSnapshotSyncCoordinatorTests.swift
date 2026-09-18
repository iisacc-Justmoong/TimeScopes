import Foundation
import XCTest
@testable import Time_Scopes

final class WidgetSnapshotSyncCoordinatorTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDown() {
        let fileManager = FileManager.default
        temporaryDirectories.forEach { directory in
            try? fileManager.removeItem(at: directory)
        }
        temporaryDirectories = []
        super.tearDown()
    }

    func testFlushNowMergesHomeAndPulsePatchesIntoSingleWrite() async {
        let container = makeContainer()
        var reloadCount = 0
        let store = WidgetSnapshotStore(container: container) {
            reloadCount += 1
        }
        let coordinator = WidgetSnapshotSyncCoordinator(store: store, debounceInterval: 60)

        let homeUpdatedAt = TestDateFactory.date("2026-02-07 10:00:00")
        let pulseUpdatedAt = TestDateFactory.date("2026-02-07 10:00:30")

        await coordinator.enqueueHomeSnapshot(
            updatedAt: homeUpdatedAt,
            profile: .init(name: "Merged Home", age: 29, monthsLeft: 610, weeksLeft: 2650, daysLeft: 18600),
            elapsed: .init(months: 310, weeks: 1320, days: 9300, hours: 220000, minutes: 13200000, seconds: 792000000),
            milestones: .init(nextDecadeAge: 30, yearsUntilNextDecade: 1, daysUntilNextBirthday: 40, weekdaysRemaining: 7800),
            highlights: .init(yearRemainingDays: 120, nextChristmasDays: 320, remainingMondays: 32),
            daily: .empty,
            requestTimelineReload: false
        )

        await coordinator.enqueuePulseSnapshot(
            updatedAt: pulseUpdatedAt,
            pulse: makePulse(weeklyPatternText: "pattern-pulse", recentEntries: []),
            requestTimelineReload: true
        )

        await coordinator.flushNow()

        let loaded = store.loadSnapshot()
        XCTAssertEqual(loaded.profile.name, "Merged Home")
        XCTAssertEqual(loaded.pulse.weeklyPatternText, "pattern-pulse")
        XCTAssertEqual(loaded.updatedAt, pulseUpdatedAt)
        XCTAssertEqual(loaded.syncVersion, 1)
        XCTAssertEqual(reloadCount, 1)
    }

    func testProfileNameAgePatchPreservesExistingRemainingValues() async {
        let container = makeContainer()
        var reloadCount = 0
        let store = WidgetSnapshotStore(container: container) {
            reloadCount += 1
        }
        let seeded = makeSnapshot(
            name: "Before",
            age: 31,
            monthsLeft: 500,
            weeksLeft: 2100,
            daysLeft: 15000,
            syncVersion: 4
        )
        store.saveSnapshot(seeded, requestTimelineReload: false)

        let coordinator = WidgetSnapshotSyncCoordinator(store: store, debounceInterval: 60)
        await coordinator.enqueueProfileNameAge(
            updatedAt: TestDateFactory.date("2026-02-07 11:00:00"),
            name: "After",
            age: 32,
            requestTimelineReload: false
        )
        await coordinator.flushNow()

        let loaded = store.loadSnapshot()
        XCTAssertEqual(loaded.profile.name, "After")
        XCTAssertEqual(loaded.profile.age, 32)
        XCTAssertEqual(loaded.profile.monthsLeft, 500)
        XCTAssertEqual(loaded.profile.weeksLeft, 2100)
        XCTAssertEqual(loaded.profile.daysLeft, 15000)
        XCTAssertEqual(loaded.syncVersion, 5)
        XCTAssertEqual(reloadCount, 0)
    }

    func testImmediatePulseRecentEntriesFlushesWithoutManualFlush() async {
        let container = makeContainer()
        var reloadCount = 0
        let store = WidgetSnapshotStore(container: container) {
            reloadCount += 1
        }
        let coordinator = WidgetSnapshotSyncCoordinator(store: store, debounceInterval: 60)

        let entries = [
            WidgetSnapshot.Pulse.JournalEntry(
                date: TestDateFactory.date("2026-02-07 12:00:00"),
                note: "First"
            ),
            WidgetSnapshot.Pulse.JournalEntry(
                date: TestDateFactory.date("2026-02-07 12:30:00"),
                note: "Second"
            )
        ]

        await coordinator.enqueuePulseRecentEntries(
            updatedAt: TestDateFactory.date("2026-02-07 12:30:00"),
            recentEntries: entries,
            requestTimelineReload: true,
            immediate: true
        )

        let loaded = store.loadSnapshot()
        XCTAssertEqual(loaded.pulse.recentEntries.map(\.note), ["First", "Second"])
        XCTAssertEqual(loaded.syncVersion, 1)
        XCTAssertEqual(reloadCount, 1)
    }

    private func makeContainer() -> WidgetSharedContainer {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("WidgetSnapshotSyncCoordinatorTests-\(UUID().uuidString)", isDirectory: true)
        temporaryDirectories.append(directory)
        return WidgetSharedContainer(appGroupID: "WidgetSnapshotSyncCoordinatorTests", fixedContainerURL: directory)
    }

    private func makeSnapshot(
        name: String,
        age: Int,
        monthsLeft: Int,
        weeksLeft: Int,
        daysLeft: Int,
        syncVersion: Int64
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            syncVersion: syncVersion,
            updatedAt: TestDateFactory.date("2026-02-07 09:00:00"),
            profile: .init(
                name: name,
                age: age,
                monthsLeft: monthsLeft,
                weeksLeft: weeksLeft,
                daysLeft: daysLeft
            ),
            elapsed: .init(months: 310, weeks: 1320, days: 9300, hours: 220000, minutes: 13200000, seconds: 792000000),
            milestones: .init(nextDecadeAge: 40, yearsUntilNextDecade: 9, daysUntilNextBirthday: 200, weekdaysRemaining: 7600),
            highlights: .init(yearRemainingDays: 150, nextChristmasDays: 300, remainingMondays: 30),
            daily: .empty,
            pulse: makePulse(weeklyPatternText: "seed", recentEntries: [])
        )
    }

    private func makePulse(
        weeklyPatternText: String,
        recentEntries: [WidgetSnapshot.Pulse.JournalEntry]
    ) -> WidgetSnapshot.Pulse {
        WidgetSnapshot.Pulse(
            todaySeries: Array(repeating: 0.2, count: 24),
            todayMax: 1,
            currentFraction: 0.5,
            weeklyDays: [
                .init(label: "Mon", intensity: 0.2),
                .init(label: "Tue", intensity: 0.4)
            ],
            weeklyPatternText: weeklyPatternText,
            weeklyPeakText: "Tue",
            weeklyLowText: "Mon",
            prescriptions: [
                .init(focus: "Focus", title: "Keep block", impact: "60m free")
            ],
            recentEntries: recentEntries
        )
    }
}
