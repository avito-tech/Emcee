import DateProviderTestHelpers
import Foundation
import Metrics
import MetricsTestHelpers
import Models
import ModelsTestHelpers
import Runner
import RunnerModels
import RunnerTestHelpers
import XCTest

final class MetricReportingTestRunnerStreamTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSinceReferenceDate: 12345))
    lazy var host = "host"
    lazy var metricHandler = FakeMetricHandler()
    lazy var stream = MetricReportingTestRunnerStream(
        dateProvider: dateProvider,
        host: host
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
    
    override func setUp() {
        GlobalMetricConfig.metricHandler = metricHandler
    }

    func test___reporting_test_started_metric() {
        stream.testStarted(testName: testName)
        
        XCTAssertEqual(
            metricHandler.metrics,
            [TestStartedMetric(host: host, testClassName: testName.className, testMethodName: testName.methodName, timestamp: dateProvider.currentDate())]
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
                    timestamp: dateProvider.currentDate()
                ),
                TestStartedMetric(
                    host: host,
                    testClassName: testName.className,
                    testMethodName: testName.methodName,
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
                    timestamp: dateProvider.currentDate()
                )
            )
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
                    timestamp: testStartedAt
                ),
                TestStartedMetric(
                    host: host,
                    testClassName: testName.className,
                    testMethodName: testName.methodName,
                    timestamp: testStartedAt
                ),
                TestFinishedMetric(
                    result: testStoppedEvent.result.rawValue,
                    host: host,
                    testClassName: testStoppedEvent.testName.className,
                    testMethodName: testStoppedEvent.testName.methodName,
                    timestamp: testStoppedAt
                ),
                TestDurationMetric(
                    result: testStoppedEvent.result.rawValue,
                    host: host,
                    testClassName: testStoppedEvent.testName.className,
                    testMethodName: testStoppedEvent.testName.methodName,
                    duration: testStoppedEvent.testDuration,
                    timestamp: testStoppedAt
                ),
                TestPostflightMetric(
                    host: host,
                    duration: 25,
                    timestamp: bucketFinishedAt
                )
            ]
        )
    }
}
