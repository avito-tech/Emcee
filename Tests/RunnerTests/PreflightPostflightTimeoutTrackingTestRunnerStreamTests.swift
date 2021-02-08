import DateProviderTestHelpers
import Foundation
import Runner
import RunnerModels
import XCTest

final class PreflightPostflightTimeoutTrackingTestRunnerStreamTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    lazy var preflightExpectation = XCTestExpectation(description: "preflight callback called")
    lazy var postflightExpectation = XCTestExpectation(description: "postflight callback called")
    
    lazy var testStream = PreflightPostflightTimeoutTrackingTestRunnerStream(
        dateProvider: dateProvider,
        onPreflightTimeout: { [weak self] in self?.preflightExpectation.fulfill() },
        onPostflightTimeout: { [weak self] _ in self?.postflightExpectation.fulfill() },
        maximumPreflightDuration: 0.01,
        maximumPostflightDuration: 0.01,
        pollPeriod: .milliseconds(1)
    )
    
    func test___preflight_is_called___when_stream_opens_and_test_does_not_start() {
        postflightExpectation.isInverted = true
        
        testStream.openStream()
        dateProvider.result += 5
        
        wait(for: [preflightExpectation, postflightExpectation], timeout: 5)
    }
    
    func test___preflight_is_not_called___when_stream_opens_and_test_starts() {
        preflightExpectation.isInverted = true
        postflightExpectation.isInverted = true
        
        testStream.openStream()
        testStream.testStarted(testName: TestName(className: "class", methodName: "test"))
        dateProvider.result += 5
        
        wait(for: [preflightExpectation, postflightExpectation], timeout: 5)
    }
    
    func test___preflight_is_not_called___when_stream_closes() {
        preflightExpectation.isInverted = true
        postflightExpectation.isInverted = true
        
        testStream.openStream()
        testStream.closeStream()
        dateProvider.result += 5
        
        wait(for: [preflightExpectation, postflightExpectation], timeout: 5)
    }
    
    func test___postflight_is_called___when_test_finished_but_next_does_not_start() {
        preflightExpectation.isInverted = true
        
        testStream.openStream()
        testStream.testStarted(
            testName: TestName(className: "class", methodName: "test1")
        )
        testStream.testStopped(
            testStoppedEvent: TestStoppedEvent(
                testName: TestName(className: "class", methodName: "test1"),
                result: .success,
                testDuration: 1,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970)
        )
        
        dateProvider.result += 5
        
        wait(for: [preflightExpectation, postflightExpectation], timeout: 5)
    }
    
    func test___postflight_is_not_called___when_test_finished_and_next_starts() {
        preflightExpectation.isInverted = true
        postflightExpectation.isInverted = true

        testStream.openStream()
        testStream.testStarted(
            testName: TestName(className: "class", methodName: "test1")
        )
        testStream.testStopped(
            testStoppedEvent: TestStoppedEvent(
                testName: TestName(className: "class", methodName: "test1"),
                result: .success,
                testDuration: 1,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970)
        )
        testStream.testStarted(
            testName: TestName(className: "class", methodName: "test2")
        )
        
        dateProvider.result += 5
        
        wait(for: [preflightExpectation, postflightExpectation], timeout: 5)
    }
    
    func test___postflight_is_not_called___when_test_finished_stream_closed() {
        preflightExpectation.isInverted = true
        postflightExpectation.isInverted = true

        testStream.openStream()
        testStream.testStarted(
            testName: TestName(className: "class", methodName: "test1")
        )
        testStream.testStopped(
            testStoppedEvent: TestStoppedEvent(
                testName: TestName(className: "class", methodName: "test1"),
                result: .success,
                testDuration: 1,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970)
        )
        testStream.closeStream()
        
        dateProvider.result += 5
        
        wait(for: [preflightExpectation, postflightExpectation], timeout: 5)
    }
}
