import XCTest
@testable import Time_Scopes

final class AppDeepLinkTests: XCTestCase {
    func testURLRoundTrip() {
        let url = AppDeepLink.url(tab: .pulse, section: "journal", item: "quick")
        let route = AppDeepLink(url: url)

        XCTAssertEqual(route?.tab, .pulse)
        XCTAssertEqual(route?.section, "journal")
        XCTAssertEqual(route?.item, "quick")
    }

    func testInvalidSchemeReturnsNil() {
        let route = AppDeepLink(url: URL(string: "https://example.com?tab=home")!)
        XCTAssertNil(route)
    }

    func testMissingTabReturnsNil() {
        let route = AppDeepLink(url: URL(string: "timescopes://open?section=profile")!)
        XCTAssertNil(route)
    }
}
