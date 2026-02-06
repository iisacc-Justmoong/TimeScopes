import Foundation
import XCTest
@testable import Time_Scopes

final class WidgetSnapshotStoreTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDown() {
        let fileManager = FileManager.default
        temporaryDirectories.forEach { directory in
            try? fileManager.removeItem(at: directory)
        }
        temporaryDirectories = []
        super.tearDown()
    }

    func testLoadSnapshotReturnsEmptyWhenFileMissing() {
        let container = makeContainer()
        let store = WidgetSnapshotStore(container: container, reloadTimeline: { _ in })

        XCTAssertEqual(store.loadSnapshot(), .empty)
    }

    func testSaveAndLoadRoundTripReloadsAllWidgetKinds() {
        let container = makeContainer()
        var reloadedKinds: [String] = []
        let store = WidgetSnapshotStore(container: container) { kind in
            reloadedKinds.append(kind)
        }

        let snapshot = makeSnapshot(name: "RoundTrip")
        store.saveSnapshot(snapshot)

        let loaded = store.loadSnapshot()
        XCTAssertEqual(loaded.profile.name, "RoundTrip")
        XCTAssertEqual(Set(reloadedKinds), Set(WidgetSharedConstants.allWidgetKinds))
        XCTAssertEqual(reloadedKinds.count, WidgetSharedConstants.allWidgetKinds.count)
    }

    func testUpdateSnapshotMutatesCurrentValueAndReloadsWidgets() {
        let container = makeContainer()
        var reloadCount = 0
        let store = WidgetSnapshotStore(container: container) { _ in
            reloadCount += 1
        }

        store.saveSnapshot(makeSnapshot(name: "Before"))
        store.updateSnapshot { current in
            WidgetSnapshot(
                updatedAt: current.updatedAt,
                profile: .init(
                    name: "After",
                    age: current.profile.age,
                    monthsLeft: current.profile.monthsLeft,
                    weeksLeft: current.profile.weeksLeft,
                    daysLeft: current.profile.daysLeft
                ),
                elapsed: current.elapsed,
                milestones: current.milestones,
                highlights: current.highlights,
                daily: current.daily,
                pulse: current.pulse
            )
        }

        let loaded = store.loadSnapshot()
        XCTAssertEqual(loaded.profile.name, "After")
        XCTAssertEqual(reloadCount, WidgetSharedConstants.allWidgetKinds.count * 2)
    }

    func testLoadSnapshotFallsBackToEmptyWhenCorrupted() throws {
        let container = makeContainer()
        let fileURL = try XCTUnwrap(container.snapshotURL)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: fileURL, options: [.atomic])

        let store = WidgetSnapshotStore(container: container, reloadTimeline: { _ in })
        XCTAssertEqual(store.loadSnapshot(), .empty)
    }

    private func makeContainer() -> WidgetSharedContainer {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("WidgetSnapshotStoreTests-\(UUID().uuidString)", isDirectory: true)
        temporaryDirectories.append(directory)
        return WidgetSharedContainer(appGroupID: "WidgetSnapshotStoreTests", fixedContainerURL: directory)
    }

    private func makeSnapshot(name: String) -> WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: TestDateFactory.date("2026-02-06 12:00:00"),
            profile: .init(name: name, age: 30, monthsLeft: 600, weeksLeft: 2600, daysLeft: 18000),
            elapsed: .init(months: 300, weeks: 1300, days: 9000, hours: 200000, minutes: 12000000, seconds: 720000000),
            milestones: .init(nextDecadeAge: 40, yearsUntilNextDecade: 10, daysUntilNextBirthday: 100, weekdaysRemaining: 8000),
            highlights: .init(yearRemainingDays: 120, nextChristmasDays: 320, remainingMondays: 30),
            daily: .empty,
            pulse: .empty
        )
    }
}
