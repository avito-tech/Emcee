import AtomicModels
import DateProvider
import Foundation
import Logging
import RunnerModels
import Timer

/// Tracks hangs that happen before starting any tests. or after fninishing any test, including in between test invocations.
public final class PreflightPostflightTimeoutTrackingTestRunnerStream: TestRunnerStream {
    private let dateProvider: DateProvider
    private let onPreflightTimeout: () -> ()
    private let onPostflightTimeout: (TestName) -> ()
    private let lastEventInfo = AtomicValue<LastEventInfo?>(nil)
    private let maximumPreflightDuration: TimeInterval
    private let maximumPostflightDuration: TimeInterval
    private let pollPeriod: DispatchTimeInterval
    private var trackingTimer: DispatchBasedTimer?
    
    struct LastEventInfo {
        let finishedTestName: TestName?
        let timestamp: Date
    }
    
    public init(
        dateProvider: DateProvider,
        onPreflightTimeout: @escaping () -> (),
        onPostflightTimeout: @escaping (TestName) -> (),
        maximumPreflightDuration: TimeInterval,
        maximumPostflightDuration: TimeInterval,
        pollPeriod: DispatchTimeInterval
    ) {
        self.dateProvider = dateProvider
        self.onPreflightTimeout = onPreflightTimeout
        self.onPostflightTimeout = onPostflightTimeout
        self.maximumPreflightDuration = maximumPreflightDuration
        self.maximumPostflightDuration = maximumPostflightDuration
        self.pollPeriod = pollPeriod
    }

    public func openStream() {
        lastEventInfo.set(
            LastEventInfo(
                finishedTestName: nil,
                timestamp: dateProvider.currentDate()
            )
        )
        startPreflightTimeoutTracking()
    }
        
    public func testStarted(testName: TestName) {
        stopAnyTracking()
    }
    
    public func caughtException(testException: TestException) {}
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        lastEventInfo.set(
            LastEventInfo(
                finishedTestName: testStoppedEvent.testName,
                timestamp: dateProvider.currentDate()
            )
        )
        startPostflightTimeoutTracking()
    }
    
    public func closeStream() {
        lastEventInfo.set(nil)
        stopAnyTracking()
    }
    
    private func startPreflightTimeoutTracking() {
        startMonitoringForHangs()
    }
    
    private func startPostflightTimeoutTracking() {
        startMonitoringForHangs()
    }
    
    private func stopAnyTracking() {
        stopMonitoringForHangs()
    }
    
    // MARK: - Logic
    
    private func startMonitoringForHangs() {
        trackingTimer = DispatchBasedTimer.startedTimer(
            repeating: pollPeriod,
            leeway: pollPeriod,
            handler: { [weak self] timer in
                guard let strongSelf = self else { return timer.stop() }
                strongSelf.processTimerFireEvent()
            }
        )
    }
    
    private func stopMonitoringForHangs() {
        trackingTimer?.stop()
        trackingTimer = nil
    }
    
    private func processTimerFireEvent() {
        guard let eventInfo = lastEventInfo.currentValue() else {
            return stopAnyTracking()
        }
        
        if let lastFinishedTestName = eventInfo.finishedTestName {
            // some tests finished - postflight
            validatePostflightTimeout(since: eventInfo.timestamp, testName: lastFinishedTestName)
        } else {
            // no tests finished yet - preflight
            validatePreflightTimeout(since: eventInfo.timestamp)
        }
    }
    
    private func validatePreflightTimeout(since date: Date) {
        if dateProvider.currentDate().timeIntervalSince(date) > maximumPostflightDuration {
            stopAnyTracking()
            onPreflightTimeout()
        }
    }
    
    private func validatePostflightTimeout(since date: Date, testName: TestName) {
        if dateProvider.currentDate().timeIntervalSince(date) > maximumPostflightDuration {
            stopAnyTracking()
            onPostflightTimeout(testName)
        }
    }
}
