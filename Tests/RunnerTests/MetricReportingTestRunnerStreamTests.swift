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
    
    override func setUp() {
        GlobalMetricConfig.metricHandler = metricHandler
    }

    func test___reporting_test_started_metric() {
        let testName = TestName(className: "class", methodName: "test")
        stream.testStarted(testName: testName)
        
        XCTAssertEqual(
            metricHandler.metrics,
            [TestStartedMetric(host: host, testClassName: testName.className, testMethodName: testName.methodName, timestamp: dateProvider.currentDate())]
        )
    }
    
    func test___reporting_test_stopped_metric() {
        let testStoppedEvent = TestStoppedEvent(
            testName: TestName(className: "class", methodName: "test"),
            result: .failure,
            testDuration: 12,
            testExceptions: [TestException(reason: "reason", filePathInProject: "file", lineNumber: 42)],
            testStartTimestamp: 111
        )
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
                    testsFinishedCount: 1,
                    timestamp: dateProvider.currentDate()
                )
            )
        )
    }
    
    func test___reporting_test_duration_metric() {
        let testStoppedEvent = TestStoppedEvent(
            testName: TestName(className: "class", methodName: "test"),
            result: .failure,
            testDuration: 12,
            testExceptions: [TestException(reason: "reason", filePathInProject: "file", lineNumber: 42)],
            testStartTimestamp: 111
        )
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
        
        let testStoppedEvent = TestStoppedEvent(
            testName: TestName(className: "class", methodName: "test"),
            result: .failure,
            testDuration: 12,
            testExceptions: [TestException(reason: "reason", filePathInProject: "file", lineNumber: 42)],
            testStartTimestamp: 111
        )
        stream.testStopped(
            testStoppedEvent: testStoppedEvent
        )
        
        dateProvider.result += timeBetweenStopOfPreviousTestAndStartOfNextTest
        let testName = TestName(className: "class", methodName: "test")
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
}
