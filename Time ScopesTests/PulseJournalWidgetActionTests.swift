import XCTest
@testable import Time_Scopes

final class PulseJournalWidgetActionTests: XCTestCase {
    private var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetSharedConstants.appGroupID) ?? .standard
    }

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: PulseJournalWidgetAction.openComposerRequestKey)
    }

    override func tearDown() {
        defaults.removeObject(forKey: PulseJournalWidgetAction.openComposerRequestKey)
        super.tearDown()
    }

    func testRequestAndConsume() {
        XCTAssertFalse(PulseJournalWidgetAction.hasPendingOpenComposerRequest)

        PulseJournalWidgetAction.requestOpenComposer()
        XCTAssertTrue(PulseJournalWidgetAction.hasPendingOpenComposerRequest)

        XCTAssertTrue(PulseJournalWidgetAction.consumeOpenComposerRequest())
        XCTAssertFalse(PulseJournalWidgetAction.hasPendingOpenComposerRequest)
    }
}
