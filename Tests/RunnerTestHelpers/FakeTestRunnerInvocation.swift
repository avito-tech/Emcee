import Foundation
import ProcessController
import Models
import Runner
import RunnerModels
import TemporaryStuff

public final class FakeTestRunnerInvocation: TestRunnerInvocation {
    private let entriesToRun: [TestEntry]
    private let testRunnerStream: TestRunnerStream
    private let testResultProvider: (TestName) -> TestStoppedEvent.Result
    private let onTestStarted: (TestName, TestRunnerStream) -> ()
    private let onTestStopped: (TestStoppedEvent, TestRunnerStream) -> ()
    private let tempFolder: TemporaryFolder
    
    public init(
        entriesToRun: [TestEntry],
        testRunnerStream: TestRunnerStream,
        testResultProvider: @escaping (TestName) -> TestStoppedEvent.Result,
        onTestStarted: @escaping (TestName, TestRunnerStream) -> (),
        onTestStopped: @escaping (TestStoppedEvent, TestRunnerStream) -> (),
        tempFolder: TemporaryFolder
    ) {
        self.entriesToRun = entriesToRun
        self.testRunnerStream = testRunnerStream
        self.testResultProvider = testResultProvider
        self.onTestStarted = onTestStarted
        self.onTestStopped = onTestStopped
        self.tempFolder = tempFolder
    }
    
    public let runningQueue = DispatchQueue(label: "FakeTestRunner")
    
    public func startExecutingTests() -> TestRunnerRunningInvocation {
        
        let group = DispatchGroup()
        
        testRunnerStream.openStream()
        
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
            self.testRunnerStream.closeStream()
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
