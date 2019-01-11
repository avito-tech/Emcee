import Foundation
import Version
import XCTest

final class VersionTests: XCTestCase {
    func test___decoding_from_plain_string() throws {
        let string = "{\"version\": \"version_value\"}"
        let result = try JSONDecoder().decode([String: Version].self, from: string.data(using: .utf8)!)
        XCTAssertEqual(
            result,
            ["version": Version(stringValue: "version_value")]
            )
    }
}

