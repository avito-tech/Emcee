import Foundation
import EmceeLogging
import RunnerModels

public enum RunnerConstants: CustomStringConvertible {
    /// Test failure reason that will be given back if test actually fails to start after all attempts to revive, even though test runner has started.
    case testDidNotRun(TestName)
    /// Test failure reason that will be given back if test runner fails to start for any reason.
    case failedToStartTestRunner(Error)
    /// Test timed out.
    case testTimeout(TimeInterval)
    
    public var description: String {
        switch self {
        case .testDidNotRun(let testName):
            return "Test \(testName) did not start after all attempts to run it"
        case .failedToStartTestRunner(let error):
            return "Test runner failed to start with error: \(error)"
        case .testTimeout(let duration):
            return "Test timed out. Test has been running longer than the given duration (\(LoggableDuration(duration)))"
        }
    }
    
    public var testException: TestException {
        TestException(reason: description, filePathInProject: "<Unknown>", lineNumber: 0)
    }
}
