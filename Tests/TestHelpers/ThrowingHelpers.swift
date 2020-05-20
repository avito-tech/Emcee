import Foundation
import XCTest

public extension XCTestCase {
    func assertDoesNotThrow<T>(
        message: (Error) -> String = { "Unexpected error thrown: \($0)" },
        file: StaticString = #file,
        line: UInt = #line,
        work: () throws -> T
    ) -> T {
        return withoutContinuingTestAfterFailure {
            do {
                return try work()
            } catch {
                failTest(message(error), file: file, line: line)
            }
        }
    }
    
    func assertThrows<T>(
        file: StaticString = #file,
        line: UInt = #line,
        work: () throws -> (T)
    ) {
        do {
            _ = try work()
            failTest("Expected to throw an error, but no error has been thrown", file: file, line: line)
        } catch {
            return
        }
    }
}
