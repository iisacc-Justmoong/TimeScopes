import XCTest
@testable import Time_Scopes

final class WidgetSharedConstantsTests: XCTestCase {
    func testAllWidgetKindsAreUnique() {
        let kinds = WidgetSharedConstants.allWidgetKinds
        XCTAssertEqual(Set(kinds).count, kinds.count)
        XCTAssertEqual(kinds.count, 9)
    }
}
