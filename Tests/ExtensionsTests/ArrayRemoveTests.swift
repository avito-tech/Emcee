import Extensions
import Foundation
import XCTest

final class ArrayRemoveTests: XCTestCase {
    func test() {
        var array = [1,1,1,2,2,1,1,1]
        array.avito_removeAll { element in element == 1 }
        XCTAssertEqual(array, [2,2])
    }
}
