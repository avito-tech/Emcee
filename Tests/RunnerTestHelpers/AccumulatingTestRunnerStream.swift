import Foundation
import Models
import Runner
import RunnerModels

public final class AccumulatingTestRunnerStream: TestRunnerStream {
    public var accumulatedData = [Any]()

    public init() {}
    
    public func testStarted(testName: TestName) {
        accumulatedData.append(testName)
    }
    
    public func caughtException(testException: TestException) {
        accumulatedData.append(testException)
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        accumulatedData.append(testStoppedEvent)
    }
    
    public func castTo<T>(_ type: T.Type, index: Int) -> T? {
        return accumulatedData[index] as? T
    }
}

