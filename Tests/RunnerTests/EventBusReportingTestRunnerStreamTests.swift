import EventBus
import Foundation
import Models
import ModelsTestHelpers
import Runner
import RunnerModels
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
    
    lazy var eventBus = EventBus()
    lazy var expectation = XCTestExpectation(description: "event bus delivered expected event")
    lazy var testContext = TestContextFixtures().testContext
    lazy var testEntry = TestEntryFixtures.testEntry()
    lazy var testException = TestException(reason: "", filePathInProject: "", lineNumber: 0)
    lazy var testStoppedEvent = TestStoppedEvent(
        testName: testEntry.testName,
        result: .failure,
        testDuration: 1,
        testExceptions: [testException],
        testStartTimestamp: 2
    )
    lazy var testStream = EventBusReportingTestRunnerStream(
        entriesToRun: [testEntry],
        eventBus: eventBus,
        testContext: testContext
    )
    lazy var unknownTestName = TestName(className: "UnknownClass", methodName: "test")
}
