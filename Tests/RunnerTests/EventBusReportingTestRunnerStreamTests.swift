import EventBus
import Foundation
import Runner
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import XCTest

final class EventBusReportingTestRunnerStreamTests: XCTestCase {
    func test___delivering_test_started_event() {
        let eventStream = BlockBasedEventStream { [testEntry, testContext, expectation] event in
            XCTAssertEqual(
                event,
                .runnerEvent(.testStarted(testEntry: testEntry, testContext: testContext))
            )
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.testStarted(testName: testEntry.testName)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___test_started_event_not_delivered_for_unknown_test_events() {
        expectation.isInverted = true
        
        let eventStream = BlockBasedEventStream { [expectation] event in
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.testStarted(testName: unknownTestName)
        
        wait(for: [expectation], timeout: 5)
    }
    
    func test___delivering_test_stopped_event() {
        let eventStream = BlockBasedEventStream { [testEntry, testContext, expectation] event in
            XCTAssertEqual(
                event,
                .runnerEvent(.testFinished(testEntry: testEntry, succeeded: false, testContext: testContext))
            )
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.testStopped(testStoppedEvent: testStoppedEvent)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___test_stopped_event_not_delivered_for_unknown_test_events() {
        expectation.isInverted = true
        
        let eventStream = BlockBasedEventStream { [expectation] event in
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.testStopped(
            testStoppedEvent: TestStoppedEvent(
                testName: unknownTestName,
                result: .failure,
                testDuration: 0,
                testExceptions: [],
                logs: [],
                testStartTimestamp: 0
            )
        )
        
        wait(for: [expectation], timeout: 5)
    }
    
    func test___exception_does_not_deliver_any_events() {
        expectation.isInverted = true

        let eventStream = BlockBasedEventStream { [expectation] event in
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.caughtException(testException: testException)
        
        wait(for: [expectation], timeout: 5)
    }
    
    func test___stream_open___delivers_will_run() {
        let eventStream = BlockBasedEventStream { [testEntry, testContext, expectation] event in
            XCTAssertEqual(
                event,
                .runnerEvent(.willRun(testEntries: [testEntry], testContext: testContext))
            )
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.openStream()
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___stream_close___delivers_did_run() {
        let eventStream = BlockBasedEventStream { [testEntryResult, testContext, expectation] event in
            XCTAssertEqual(
                event,
                .runnerEvent(.didRun(results: [testEntryResult], testContext: testContext))
            )
            expectation.fulfill()
        }
        eventBus.add(stream: eventStream)
        
        testStream.closeStream()
        
        wait(for: [expectation], timeout: 10)
    }
    
    lazy var eventBus = EventBus()
    lazy var expectation = XCTestExpectation(description: "event bus delivered expected event")
    lazy var testContext = TestContextFixtures().testContext
    lazy var testEntry = TestEntryFixtures.testEntry()
    lazy var testEntryResult = TestEntryResult.withResult(testEntry: testEntry, testRunResult: testRunResult)
    lazy var testException = TestException(reason: "", filePathInProject: "", lineNumber: 0, relatedTestName: nil)
    lazy var testRunResult = TestRunResult(
        succeeded: true,
        exceptions: [testException],
        logs: [],
        duration: 5,
        startTime: 5,
        hostName: "host",
        simulatorId: UDID(value: "UDID")
    )
    lazy var testStoppedEvent = TestStoppedEvent(
        testName: testEntry.testName,
        result: .failure,
        testDuration: 1,
        testExceptions: [testException],
        logs: [],
        testStartTimestamp: 2
    )
    lazy var testStream = EventBusReportingTestRunnerStream(
        entriesToRun: [testEntry],
        eventBus: eventBus,
        logger: { .noOp },
        testContext: testContext,
        resultsProvider: { [weak self] in
            guard let strongSelf = self else { return [] }
            return [strongSelf.testEntryResult]
        }
    )
    lazy var unknownTestName = TestName(className: "UnknownClass", methodName: "test")
}
