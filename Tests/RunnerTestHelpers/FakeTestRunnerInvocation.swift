import CommonTestModels
import EmceeTypes
import Foundation
import Runner

public final class FakeTestRunnerInvocation: TestRunnerInvocation {
    private let entriesToRun: [TestEntry]
    private let testRunnerStream: TestRunnerStream
    private let testResultProvider: (TestName) -> TestStoppedEvent.Result
    private let onStreamOpen: (TestRunnerStream) -> ()
    private let onTestStarted: (TestName, TestRunnerStream) -> ()
    private let onTestStopped: (TestStoppedEvent, TestRunnerStream) -> ()
    private let onStreamClose: (TestRunnerStream) -> ()
    
    public init(
        entriesToRun: [TestEntry],
        testRunnerStream: TestRunnerStream,
        testResultProvider: @escaping (TestName) -> TestStoppedEvent.Result,
        onStreamOpen: @escaping (TestRunnerStream) -> (),
        onTestStarted: @escaping (TestName, TestRunnerStream) -> (),
        onTestStopped: @escaping (TestStoppedEvent, TestRunnerStream) -> (),
        onStreamClose: @escaping (TestRunnerStream) -> ()
    ) {
        self.entriesToRun = entriesToRun
        self.testRunnerStream = testRunnerStream
        self.testResultProvider = testResultProvider
        self.onStreamOpen = onStreamOpen
        self.onTestStarted = onTestStarted
        self.onTestStopped = onTestStopped
        self.onStreamClose = onStreamClose
    }
    
    public let runningQueue = DispatchQueue(label: "FakeTestRunner")
    
    public func startExecutingTests() -> TestRunnerRunningInvocation {
        
        let group = DispatchGroup()
        
        onStreamOpen(testRunnerStream)
        
        var isCancelled = false
        
        for testEntry in entriesToRun {
            group.enter()
            
            runningQueue.async {
                let testStartTimestamp = DateSince1970ReferenceDate(timeIntervalSince1970: Date().timeIntervalSince1970)
                if !isCancelled {
                    self.onTestStarted(testEntry.testName, self.testRunnerStream)
                }
                
                self.runningQueue.async {
                    let testResult = self.testResultProvider(testEntry.testName)
                    
                    self.runningQueue.async {
                        let testStoppedEvent = TestStoppedEvent(
                            testName: testEntry.testName,
                            result: testResult,
                            testDuration: Date().timeIntervalSince(testStartTimestamp.date),
                            testExceptions: [],
                            logs: [],
                            testStartTimestamp: testStartTimestamp
                        )
                        
                        if !isCancelled {
                            self.onTestStopped(testStoppedEvent, self.testRunnerStream)
                        }
                        
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: runningQueue) {
            self.onStreamClose(self.testRunnerStream)
        }
        
        let runningInvocation = FakeTestRunnerRunningInvocation()
        runningInvocation.onWait = group.wait
        runningInvocation.onCancel = {
            isCancelled = true
        }
        return runningInvocation
    }
}
