import AtomicModels
import DateProvider
import Foundation
import Logging
import Models
import RunnerModels
import Timer

public final class TestTimeoutTrackingTestRunnerSream: TestRunnerStream {
    struct LastStartedTestInfo {
        let testName: TestName
        let testStartedAt: Date
    }
    
    private let dateProvider: DateProvider
    private let detectedLongRunningTest: (TestName, Date) -> ()
    private let lastStartedTestInfo = AtomicValue<LastStartedTestInfo?>(nil)
    private let maximumTestDuration: TimeInterval
    private var testHangTrackingTimer: DispatchBasedTimer?
    
    public init(
        dateProvider: DateProvider,
        detectedLongRunningTest: @escaping (TestName, Date) -> (),
        maximumTestDuration: TimeInterval
    ) {
        self.dateProvider = dateProvider
        self.detectedLongRunningTest = detectedLongRunningTest
        self.maximumTestDuration = maximumTestDuration
    }
    
    public func caughtException(testException: TestException) {}
    
    public func testStarted(testName: TestName) {
        startMonitoringForHangs(testName: testName)
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        stopMonitoringForHangs(testStoppedEvent: testStoppedEvent)
    }
    
    private func startMonitoringForHangs(testName: TestName) {
        lastStartedTestInfo.set(
            LastStartedTestInfo(testName: testName, testStartedAt: dateProvider.currentDate())
        )
        
        testHangTrackingTimer = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) { [weak self] timer in
            guard let strongSelf = self else { return timer.stop() }
            guard let lastStartedTestInfo = strongSelf.lastStartedTestInfo.currentValue() else { return timer.stop() }
            
            if strongSelf.dateProvider.currentDate().timeIntervalSince(lastStartedTestInfo.testStartedAt) > strongSelf.maximumTestDuration {
                strongSelf.didDetectLongRunningTest(lastStartedTestInfo: lastStartedTestInfo)
                timer.stop()
            }
        }
        
        Logger.debug("Started monitoring duration of test \(testName)")
    }
    
    private func stopMonitoringForHangs(testStoppedEvent: TestStoppedEvent) {
        lastStartedTestInfo.set(nil)
        
        testHangTrackingTimer?.stop()
        testHangTrackingTimer = nil
        
        Logger.debug("Stopped monitoring duration of test \(testStoppedEvent.testName), test finished with result \(testStoppedEvent.result)")
    }
    
    private func didDetectLongRunningTest(lastStartedTestInfo: LastStartedTestInfo) {
        Logger.warning("Detected a long running test: \(lastStartedTestInfo.testName) was running for more than \(LoggableDuration(maximumTestDuration)), test started at: \(LoggableDate(lastStartedTestInfo.testStartedAt))")
        
        detectedLongRunningTest(lastStartedTestInfo.testName, lastStartedTestInfo.testStartedAt)
    }
}
