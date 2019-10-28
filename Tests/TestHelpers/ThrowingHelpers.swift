import Foundation
import XCTest

public extension XCTestCase {
    func assertDoesNotThrow<T>(
        _ closure: @autoclosure () throws -> T,
        message: (Error) -> String = { "Unexpected error thrown: \($0)" },
        file: StaticString = #file,
        line: UInt = #line
    ) -> T {
        let shouldContinue = continueAfterFailure
        defer { continueAfterFailure = shouldContinue }
        continueAfterFailure = false
        
        do {
            return try closure()
        } catch {
            let explanation = message(error)
            XCTFail(explanation, file: file, line: line)
            fatalError(explanation)
        }
    }
}
