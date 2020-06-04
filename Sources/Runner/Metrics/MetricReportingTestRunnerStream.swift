import AtomicModels
import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import Models
import RunnerModels
import TestRunner

public final class MetricReportingTestRunnerStream: TestRunnerStream {
    private let dateProvider: DateProvider
    private let delegate: TestRunnerStream
    private let host: String
    private let lastTestStoppedEventTimestamp = AtomicValue<Date?>(nil)
    
    public init(
        dateProvider: DateProvider,
        delegate: TestRunnerStream,
        host: String = LocalHostDeterminer.currentHostAddress
    ) {
        self.dateProvider = dateProvider
        self.delegate = delegate
        self.host = host
    }
    
    public func testStarted(testName: TestName) {
        MetricRecorder.capture(
            TestStartedMetric(
                host: host,
                testClassName: testName.className,
                testMethodName: testName.methodName,
                timestamp: dateProvider.currentDate()
            )
        )
        
        if let timestamp = lastTestStoppedEventTimestamp.currentValue() {
            MetricRecorder.capture(
                TimeBetweenTestsMetric(
                    host: host,
                    duration: dateProvider.currentDate().timeIntervalSince(timestamp),
                    timestamp: dateProvider.currentDate()
                )
            )
            lastTestStoppedEventTimestamp.set(nil)
        }
        
        delegate.testStarted(testName: testName)
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        
        MetricRecorder.capture(
            TestFinishedMetric(
                result: testStoppedEvent.result.rawValue,
                host: host,
                testClassName: testStoppedEvent.testName.className,
                testMethodName: testStoppedEvent.testName.methodName,
                testsFinishedCount: 1,
                timestamp: dateProvider.currentDate()
            ),
            TestDurationMetric(
                result: testStoppedEvent.result.rawValue,
                host: host,
                testClassName: testStoppedEvent.testName.className,
                testMethodName: testStoppedEvent.testName.methodName,
                duration: testStoppedEvent.testDuration,
                timestamp: dateProvider.currentDate()
            )
        )
        
        lastTestStoppedEventTimestamp.set(dateProvider.currentDate())
        
        delegate.testStopped(testStoppedEvent: testStoppedEvent)
    }
    
    public func caughtException(testException: TestException) {
        delegate.caughtException(testException: testException)
    }
}
