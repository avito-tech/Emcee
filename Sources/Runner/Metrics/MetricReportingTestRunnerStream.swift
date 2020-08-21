import AtomicModels
import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import QueueModels
import RunnerModels

public final class MetricReportingTestRunnerStream: TestRunnerStream {
    private let dateProvider: DateProvider
    private let host: String
    private let lastTestStoppedEventTimestamp = AtomicValue<Date?>(nil)
    private let version: Version
    private let willRunEventTimestamp = AtomicValue<Date?>(nil)
    
    public init(
        dateProvider: DateProvider,
        host: String,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.host = host
        self.version = version
    }
    
    public func openStream() {
        willRunEventTimestamp.set(dateProvider.currentDate())
    }
    
    public func testStarted(testName: TestName) {
        willRunEventTimestamp.withExclusiveAccess { value in
            if let willRunEventTimestamp = value {
                MetricRecorder.capture(
                    TestPreflightMetric(
                        host: host,
                        duration: dateProvider.currentDate().timeIntervalSince(willRunEventTimestamp),
                        version: version,
                        timestamp: dateProvider.currentDate()
                    )
                )
                value = nil
            }
        }
        
        MetricRecorder.capture(
            TestStartedMetric(
                host: host,
                testClassName: testName.className,
                testMethodName: testName.methodName,
                version: version,
                timestamp: dateProvider.currentDate()
            )
        )
        
        if let timestamp = lastTestStoppedEventTimestamp.currentValue() {
            MetricRecorder.capture(
                TimeBetweenTestsMetric(
                    host: host,
                    duration: dateProvider.currentDate().timeIntervalSince(timestamp),
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            )
            lastTestStoppedEventTimestamp.set(nil)
        }
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        MetricRecorder.capture(
            TestFinishedMetric(
                result: testStoppedEvent.result.rawValue,
                host: host,
                testClassName: testStoppedEvent.testName.className,
                testMethodName: testStoppedEvent.testName.methodName,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            TestDurationMetric(
                result: testStoppedEvent.result.rawValue,
                host: host,
                testClassName: testStoppedEvent.testName.className,
                testMethodName: testStoppedEvent.testName.methodName,
                duration: testStoppedEvent.testDuration,
                version: version,
                timestamp: dateProvider.currentDate()
            )
        )
        
        lastTestStoppedEventTimestamp.set(dateProvider.currentDate())
    }
    
    public func caughtException(testException: TestException) {}
    
    public func closeStream() {
        lastTestStoppedEventTimestamp.withExclusiveAccess { value in
            if let lastTestStoppedEventTimestamp = value {
                MetricRecorder.capture(
                    TestPostflightMetric(
                        host: host,
                        duration: dateProvider.currentDate().timeIntervalSince(lastTestStoppedEventTimestamp),
                        version: version,
                        timestamp: dateProvider.currentDate()
                    )
                )
            }
            value = nil
        }
        
        willRunEventTimestamp.withExclusiveAccess { value in
            if let streamOpenEventTimestamp = value {
                MetricRecorder.capture(
                    UselessTestRunnerInvocationMetric(
                        host: host,
                        version: version,
                        duration: dateProvider.currentDate().timeIntervalSince(streamOpenEventTimestamp),
                        timestamp: dateProvider.currentDate()
                    )
                )
            }
        }
    }
}
