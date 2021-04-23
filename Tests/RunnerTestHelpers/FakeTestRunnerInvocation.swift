import Foundation
import ProcessController
import Runner
import RunnerModels
import Tmp

public final class FakeTestRunnerInvocation: TestRunnerInvocation {
    private let entriesToRun: [TestEntry]
    private let testRunnerStream: TestRunnerStream
    private let testResultProvider: (TestName) -> TestStoppedEvent.Result
    private let onStreamOpen: (TestRunnerStream) -> ()
    private let onTestStarted: (TestName, TestRunnerStream) -> ()
    private let onTestStopped: (TestStoppedEvent, TestRunnerStream) -> ()
    private let onStreamClose: (TestRunnerStream) -> ()
    private let tempFolder: TemporaryFolder
    
    public init(
        entriesToRun: [TestEntry],
        testRunnerStream: TestRunnerStream,
        testResultProvider: @escaping (TestName) -> TestStoppedEvent.Result,
        onStreamOpen: @escaping (TestRunnerStream) -> (),
        onTestStarted: @escaping (TestName, TestRunnerStream) -> (),
        onTestStopped: @escaping (TestStoppedEvent, TestRunnerStream) -> (),
        onStreamClose: @escaping (TestRunnerStream) -> (),
        tempFolder: TemporaryFolder
    ) {
        self.entriesToRun = entriesToRun
        self.testRunnerStream = testRunnerStream
        self.testResultProvider = testResultProvider
        self.onStreamOpen = onStreamOpen
        self.onTestStarted = onTestStarted
        self.onTestStopped = onTestStopped
        self.onStreamClose = onStreamClose
        self.tempFolder = tempFolder
    }
    
    public let runningQueue = DispatchQueue(label: "FakeTestRunner")
    
    public func startExecutingTests() -> TestRunnerRunningInvocation {
        
        let group = DispatchGroup()
        
        onStreamOpen(testRunnerStream)
        
        var isCancelled = false
        
        for testEntry in entriesToRun {
            group.enter()
            
            runningQueue.async {
                let testStartTimestamp = Date()
                if !isCancelled {
                    self.onTestStarted(testEntry.testName, self.testRunnerStream)
                }
                
                self.runningQueue.async {
                    let testResult = self.testResultProvider(testEntry.testName)
                    
                    self.runningQueue.async {
                        let testStoppedEvent = TestStoppedEvent(
                            testName: testEntry.testName,
                            result: testResult,
                            testDuration: Date().timeIntervalSince(testStartTimestamp),
                            testExceptions: [],
                            logs: [],
                            testStartTimestamp: testStartTimestamp.timeIntervalSince1970
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
        
        let runningInvocation = FakeTestRunnerRunningInvocation(
            tempFolder: tempFolder
        )
        runningInvocation.onWait = group.wait
        runningInvocation.onCancel = {
            isCancelled = true
        }
        return runningInvocation
    }
}
