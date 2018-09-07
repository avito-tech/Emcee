import FileCache
import Foundation
import XCTest

final class SHA256NameKeyerTests: XCTestCase {
    func test() {
        XCTAssertEqual(
            try SHA256NameKeyer().key(forName: "input").uppercased(),
            "C96C6D5BE8D08A12E7B5CDC1B207FA6B2430974C86803D8891675E76FD992C20")
    }
}
