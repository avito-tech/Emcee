import Foundation
import XCTest

public extension XCTestCase {
    func withoutContinuingTestAfterFailure<T>(
        work: () -> T
    ) -> T {
        let shouldContinue = continueAfterFailure
        defer { continueAfterFailure = shouldContinue }
        
        continueAfterFailure = false
        return work()
    }
}
