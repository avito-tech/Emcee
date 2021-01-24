import Foundation
import XCTest

public func assert<T: Equatable>(
    file: StaticString = #file,
    line: UInt = #line,
    left: () throws -> T,
    equals right: () throws -> T
) {
    do {
        let leftResult = try left()
        let rightResult = try right()
        
        if leftResult != rightResult {
            XCTFail("Values not equal.\nLeft value: \n\(leftResult)\nRight value:\n\(rightResult)", file: file, line: line)
        }
    } catch {
        XCTFail("Error thrown during value comparison.\nError: \(error)", file: file, line: line)
    }
}
