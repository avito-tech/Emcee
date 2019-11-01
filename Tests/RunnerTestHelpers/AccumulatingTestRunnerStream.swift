import Foundation
import Models
import Runner

public final class AccumulatingTestRunnerStream: TestRunnerStream {
    public var accumulatedData = [Either<TestName, TestStoppedEvent>]()

    public init() {}
    
    public func testStarted(testName: TestName) {
        accumulatedData.append(Either.left(testName))
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        accumulatedData.append(Either.right(testStoppedEvent))
    }
}

