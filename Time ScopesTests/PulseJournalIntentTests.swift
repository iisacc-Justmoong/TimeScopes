import XCTest
@testable import Time_Scopes

@available(iOS 17.0, *)
final class PulseJournalIntentTests: XCTestCase {
    func testPerformRequestsComposerOpenAction() async throws {
        _ = PulseJournalWidgetAction.consumeOpenComposerRequest()

        let intent = AddPulseJournalEntryIntent()
        _ = try await intent.perform()

        XCTAssertTrue(PulseJournalWidgetAction.consumeOpenComposerRequest())
    }
}
