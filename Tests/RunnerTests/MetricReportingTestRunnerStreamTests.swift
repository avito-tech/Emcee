import DateProviderTestHelpers
import Foundation
import Metrics
import MetricsTestHelpers
import QueueModels
import Runner
import RunnerModels
import RunnerTestHelpers
import XCTest

final class MetricReportingTestRunnerStreamTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSinceReferenceDate: 12345))
    lazy var host = "host"
    lazy var metricHandler = FakeMetricHandler<GraphiteMetric>()
    lazy var stream = MetricReportingTestRunnerStream(
        dateProvider: dateProvider,
        host: host,
        version: version
    )
    lazy var testName = TestName(className: "class", methodName: "test")
    lazy var testContext = TestContextFixtures().testContext
    lazy var testStoppedEvent = TestStoppedEvent(
        testName: testName,
        result: .failure,
        testDuration: 12,
        testExceptions: [TestException(reason: "reason", filePathInProject: "file", lineNumber: 42)],
        testStartTimestamp: 111
    )
    lazy var version = Version(value: "version")
    
    override func setUp() {
        GlobalMetricConfig.graphiteMetricHandler = metricHandler
    }

    func test___reporting_test_started_metric() {
        stream.testStarted(testName: testName)
        
        XCTAssertEqual(
            metricHandler.metrics,
            [
                TestStartedMetric(
                    host: host,
                    testClassName: testName.className,
                    testMethodName: testName.methodName,
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            ]
        )
    }
    
    func test___reporting_test_stopped_metric() {
        stream.testStopped(
            testStoppedEvent: testStoppedEvent
        )
        
        XCTAssertTrue(
            metricHandler.metrics.contains(
                TestFinishedMetric(
                    result: testStoppedEvent.result.rawValue,
                    host: host,
                    testClassName: testStoppedEvent.testName.className,
                    testMethodName: testStoppedEvent.testName.methodName,
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            )
        )
    }
    
    func test___reporting_test_duration_metric() {
        stream.testStopped(
            testStoppedEvent: testStoppedEvent
        )
        
        XCTAssertTrue(
            metricHandler.metrics.contains(
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
        )
    }
    
    func test___reporting_time_between_tests_metric() {
        let timeBetweenStopOfPreviousTestAndStartOfNextTest: TimeInterval = 100
        
        
        stream.testStopped(
            testStoppedEvent: testStoppedEvent
        )
        
        dateProvider.result += timeBetweenStopOfPreviousTestAndStartOfNextTest
        stream.testStarted(testName: testName)
        
        XCTAssertTrue(
            metricHandler.metrics.contains(
                TimeBetweenTestsMetric(
                    host: host,
                    duration: timeBetweenStopOfPreviousTestAndStartOfNextTest,
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            )
        )
    }
    
    func test___reports_preflight_metric___after_first_test_starts() {
        stream.openStream()
        dateProvider.result += 100
        stream.testStarted(testName: testName)
        
        XCTAssertEqual(
            metricHandler.metrics,
            [
                TestPreflightMetric(
                    host: host,
                    duration: 100,
                    version: version,
                    timestamp: dateProvider.currentDate()
                ),
                TestStartedMetric(
                    host: host,
                    testClassName: testName.className,
                    testMethodName: testName.methodName,
                    version: version,
                    timestamp: dateProvider.currentDate()
                ),
            ]
        )
    }
    
    func test___reports_postflight_metric___after_last_test_finishes() {
        stream.testStarted(testName: testName)
        stream.testStopped(testStoppedEvent: testStoppedEvent)
        dateProvider.result += 100
        stream.closeStream()
        
        XCTAssert(
            metricHandler.metrics.contains(
                TestPostflightMetric(
                    host: host,
                    duration: 100,
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            )
        )
    }
    
    func test___reports_useless_runner_invocation_metric___when_stream_opens_and_closes___without_running_tests() {
        stream.openStream()
        dateProvider.result += 25
        stream.closeStream()
        
        XCTAssertEqual(
            metricHandler.metrics,
            [
                UselessTestRunnerInvocationMetric(
                    host: host,
                    version: version,
                    duration: 25,
                    timestamp: dateProvider.currentDate()
                )
            ]
        )
    }
    
    func test___complex_metric_reporting() {
        stream.openStream()
        dateProvider.result += 25
        
        let testStartedAt = dateProvider.currentDate()
        stream.testStarted(testName: testName)
        dateProvider.result += 25
        
        let testStoppedAt = dateProvider.currentDate()
        stream.testStopped(testStoppedEvent: testStoppedEvent)
        dateProvider.result += 25
        
        let bucketFinishedAt = dateProvider.currentDate()
        stream.closeStream()
        
        XCTAssertEqual(
            metricHandler.metrics,
            [
                TestPreflightMetric(
                    host: host,
                    duration: 25,
                    version: version,
                    timestamp: testStartedAt
                ),
                TestStartedMetric(
                    host: host,
                    testClassName: testName.className,
                    testMethodName: testName.methodName,
                    version: version,
                    timestamp: testStartedAt
                ),
                TestFinishedMetric(
                    result: testStoppedEvent.result.rawValue,
                    host: host,
                    testClassName: testStoppedEvent.testName.className,
                    testMethodName: testStoppedEvent.testName.methodName,
                    version: version,
                    timestamp: testStoppedAt
                ),
                TestDurationMetric(
                    result: testStoppedEvent.result.rawValue,
                    host: host,
                    testClassName: testStoppedEvent.testName.className,
                    testMethodName: testStoppedEvent.testName.methodName,
                    duration: testStoppedEvent.testDuration,
                    version: version,
                    timestamp: testStoppedAt
                ),
                TestPostflightMetric(
                    host: host,
                    duration: 25,
                    version: version,
                    timestamp: bucketFinishedAt
                ),
            ]
        )
    }
}
