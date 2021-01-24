import Foundation
import TestHelpers
import XCTest

extension XCTestCase {
    func check<T: Equatable & Decodable>(input: String, equals object: T) {
        let data = assertNotNil { input.data(using: .utf8) }
        assert {
            try JSONDecoder().decode(T.self, from: data)
        } equals: {
            object
        }
    }
}
