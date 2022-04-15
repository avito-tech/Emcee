import AtomicModels
import CommonTestModels
import DateProvider
import Foundation
import MetricsRecording
import MetricsExtensions
import QueueModels

public final class MetricReportingTestRunnerStream: TestRunnerStream {
    private let dateProvider: DateProvider
    private let version: Version
    private let host: String
    private let persistentMetricsJobId: String?
    private let lastTestStoppedEventTimestamp = AtomicValue<Date?>(nil)
    private let willRunEventTimestamp = AtomicValue<Date?>(nil)
    private let specificMetricRecorder: SpecificMetricRecorder
    
    public init(
        dateProvider: DateProvider,
        version: Version,
        host: String,
        persistentMetricsJobId: String?,
        specificMetricRecorder: SpecificMetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.host = host
        self.version = version
        self.persistentMetricsJobId = persistentMetricsJobId
        self.specificMetricRecorder = specificMetricRecorder
    }
    
    public func openStream() {
        willRunEventTimestamp.set(dateProvider.currentDate())
    }
    
    public func testStarted(testName: TestName) {
        willRunEventTimestamp.withExclusiveAccess { value in
            if let willRunEventTimestamp = value {
                specificMetricRecorder.capture(
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
        
        specificMetricRecorder.capture(
            TestStartedMetric(
                host: host,
                testClassName: testName.className,
                testMethodName: testName.methodName,
                version: version,
                timestamp: dateProvider.currentDate()
            )
        )
        
        if let timestamp = lastTestStoppedEventTimestamp.currentValue() {
            specificMetricRecorder.capture(
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
        specificMetricRecorder.capture(
            TestFinishedMetric(
                result: testStoppedEvent.result.rawValue,
                host: host,
                testClassName: testStoppedEvent.testName.className,
                testMethodName: testStoppedEvent.testName.methodName,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            ConcreteTestDurationMetric(
                result: testStoppedEvent.result.rawValue,
                host: host,
                testClassName: testStoppedEvent.testName.className,
                testMethodName: testStoppedEvent.testName.methodName,
                duration: testStoppedEvent.testDuration,
                version: version,
                timestamp: dateProvider.currentDate()
            )
        )
        if let persistentMetricsJobId = persistentMetricsJobId {
            specificMetricRecorder.capture(
                AggregatedTestsDurationMetric(
                    result: testStoppedEvent.result.rawValue,
                    host: host,
                    version: version,
                    persistentMetricsJobId: persistentMetricsJobId,
                    duration: testStoppedEvent.testDuration
                )
            )
        }
        
        lastTestStoppedEventTimestamp.set(dateProvider.currentDate())
    }
    
    public func caughtException(testException: TestException) {}
    
    public func logCaptured(entry: TestLogEntry) {}
    
    public func closeStream() {
        lastTestStoppedEventTimestamp.withExclusiveAccess { value in
            if let lastTestStoppedEventTimestamp = value {
                specificMetricRecorder.capture(
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
        
        if let streamOpenEventTimestamp = willRunEventTimestamp.currentValue() {
            specificMetricRecorder.capture(
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
