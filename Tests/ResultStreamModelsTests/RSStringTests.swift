import Foundation
import ResultStreamModels
import XCTest

final class RSStringTests: XCTestCase {
    func test() throws {
        let input = """
        {
            "_type": {
                "_name": "String"
            },
            "_value": "hello"
        }
        """
        check(input: input, equals: RSString("hello"))
    }
}
