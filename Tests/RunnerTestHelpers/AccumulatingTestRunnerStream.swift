import Foundation
import Runner
import RunnerModels

public final class AccumulatingTestRunnerStream: TestRunnerStream {
    public var accumulatedData = [Any]()

    public init() {}
    
    public var streamIsOpen = false
    
    public func openStream() {
        streamIsOpen = true
    }
    
    public func testStarted(testName: TestName) {
        accumulatedData.append(testName)
    }
    
    public func caughtException(testException: TestException) {
        accumulatedData.append(testException)
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        accumulatedData.append(testStoppedEvent)
    }
    
    public var onCloseStream: () -> () = {}
    
    public func closeStream() {
        streamIsOpen = false
        onCloseStream()
    }
    
    public func castTo<T>(_ type: T.Type, index: Int) -> T? {
        return accumulatedData[index] as? T
    }
}

