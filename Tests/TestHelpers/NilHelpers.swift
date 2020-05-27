import Foundation
import XCTest

public extension XCTestCase {
    @discardableResult
    func assertNotNil<T>(
        file: StaticString = #file,
        line: UInt = #line,
        work: () throws -> T?
    ) rethrows -> T {
        guard let value = try work() else {
            failTest("Unexpected nil value", file: file, line: line)
        }
        return value
    }
}
