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
                let explanation = message(error)
                XCTFail(explanation, file: file, line: line)
                fatalError(explanation, file: file, line: line)
            }
        }
    }
    
    func assertThrows(
        file: StaticString = #file,
        line: UInt = #line,
        work: () throws -> ()
    ) {
        do {
            try work()
            XCTFail("Expected to throw an error, but no error has been thrown", file: file, line: line)
        } catch {
            return
        }
    }
}
