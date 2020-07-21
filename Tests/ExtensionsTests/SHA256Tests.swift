import Foundation
import XCTest

final class SHA256Tests: XCTestCase {
    func test() throws {
        XCTAssertEqual(
            try "string".avito_sha256Hash().uppercased(),
            "473287F8298DBA7163A897908958F7C0EAE733E25D2E027992EA2EDC9BED2FA8")
    }
}
