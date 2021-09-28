import AtomicModels
import DateProvider
import Foundation
import EmceeLogging
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
    private let logger: () -> ContextualLogger
    private let maximumTestDuration: TimeInterval
    private let pollPeriod: DispatchTimeInterval
    private var testHangTrackingTimer: DispatchBasedTimer?
    
    public init(
        dateProvider: DateProvider,
        detectedLongRunningTest: @escaping (TestName, Date) -> (),
        logger: @escaping () -> ContextualLogger,
        maximumTestDuration: TimeInterval,
        pollPeriod: DispatchTimeInterval
    ) {
        self.dateProvider = dateProvider
        self.detectedLongRunningTest = detectedLongRunningTest
        self.logger = logger
        self.maximumTestDuration = maximumTestDuration
        self.pollPeriod = pollPeriod
    }
    
    public func openStream() {}
        
    public func testStarted(testName: TestName) {
        startMonitoringForHangs(testName: testName)
    }
    
    public func caughtException(testException: TestException) {}
    
    public func logCaptured(entry: TestLogEntry) {}
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        stopMonitoringForHangs(testStoppedEvent: testStoppedEvent)
    }
    
    public func closeStream() {
        stopTimer()
    }
    
    private func startMonitoringForHangs(testName: TestName) {
        lastStartedTestInfo.set(
            LastStartedTestInfo(testName: testName, testStartedAt: dateProvider.currentDate())
        )
        
        testHangTrackingTimer = DispatchBasedTimer.startedTimer(repeating: pollPeriod, leeway: pollPeriod) { [weak self] timer in
            guard let strongSelf = self else { return timer.stop() }
            guard let lastStartedTestInfo = strongSelf.lastStartedTestInfo.currentValue() else { return timer.stop() }
            
            if strongSelf.dateProvider.currentDate().timeIntervalSince(lastStartedTestInfo.testStartedAt) > strongSelf.maximumTestDuration {
                strongSelf.didDetectLongRunningTest(lastStartedTestInfo: lastStartedTestInfo)
                timer.stop()
            }
        }
        
        logger().debug("Started monitoring duration of test \(testName)")
    }
    
    private func stopMonitoringForHangs(testStoppedEvent: TestStoppedEvent) {
        stopTimer()
        logger().debug("Stopped monitoring duration of test \(testStoppedEvent.testName), test finished with result \(testStoppedEvent.result)")
    }
    
    private func didDetectLongRunningTest(lastStartedTestInfo: LastStartedTestInfo) {
        logger().warning("Detected a long running test: \(lastStartedTestInfo.testName) was running for more than \(LoggableDuration(maximumTestDuration)), test started at: \(LoggableDate(lastStartedTestInfo.testStartedAt))")
        
        detectedLongRunningTest(lastStartedTestInfo.testName, lastStartedTestInfo.testStartedAt)
    }
    
    private func stopTimer() {
        lastStartedTestInfo.set(nil)
        testHangTrackingTimer?.stop()
        testHangTrackingTimer = nil
    }
}
