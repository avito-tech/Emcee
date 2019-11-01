import AppleTools
import DateProvider
import DateProviderTestHelpers
import Foundation
import Models
import RunnerTestHelpers
import TestHelpers
import XCTest

final class XcodebuildLogParserTests: XCTestCase {
    private let dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    private let accumulatingTestRunnerStream = AccumulatingTestRunnerStream()
    
    func test___parsing_unrelated_string___produces_no_event() {
        let parser = assertDoesNotThrow {
            try XcodebuildLogParser(dateProvider: dateProvider)
        }
        
        assertDoesNotThrow {
            try parser.parse(string: "", testRunnerStream: accumulatingTestRunnerStream)
            try parser.parse(string: "abc", testRunnerStream: accumulatingTestRunnerStream)
        }
        
        XCTAssertTrue(accumulatingTestRunnerStream.accumulatedData.isEmpty)
    }
    
    func test___parsing_test_start___produces_test_start_event() {
        let parser = assertDoesNotThrow {
            try XcodebuildLogParser(dateProvider: dateProvider)
        }
        
        assertDoesNotThrow {
            try parser.parse(
                string: "Test Case '-[ModuleWithTests.TestClassName testMethodName]' started.",
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.accumulatedData,
            [
                Either.left(TestName(className: "TestClassName", methodName: "testMethodName"))
            ]
        )
    }
    
    func test___parsing_test_passed____produces_test_stopped_event() {
        let parser = assertDoesNotThrow {
            try XcodebuildLogParser(dateProvider: dateProvider)
        }
        
        assertDoesNotThrow {
            try parser.parse(
                string: "Test Case '-[UITests.SomeTest_1234 test]' passed (22.128 seconds).",
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.accumulatedData,
            [
                Either.right(
                    TestStoppedEvent(
                        testName: TestName(className: "SomeTest_1234", methodName: "test"),
                        result: .success,
                        testDuration: 22.128,
                        testExceptions: [],
                        testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
                    )
                )
            ]
        )
    }
    
    func test___parsing_test_failed____produces_test_stopped_event() {
        let parser = assertDoesNotThrow {
            try XcodebuildLogParser(dateProvider: dateProvider)
        }
        
        assertDoesNotThrow {
            try parser.parse(
                string: "Test Case '-[UITests.SomeTest_1234 test]' failed (22.128 seconds).",
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.accumulatedData,
            [
                Either.right(
                    TestStoppedEvent(
                        testName: TestName(className: "SomeTest_1234", methodName: "test"),
                        result: .failure,
                        testDuration: 22.128,
                        testExceptions: [],
                        testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
                    )
                )
            ]
        )
    }
    
    func test___parsing_multiline_string() {
        let parser = assertDoesNotThrow {
            try XcodebuildLogParser(dateProvider: dateProvider)
        }
        
        assertDoesNotThrow {
            try parser.parse(
                string: """
                Test Case '-[ModuleWithTests.TestClassName testMethodName]' started.
                Test Case '-[ModuleWithTests.TestClassName testAnother]' started.
                Test Case '-[ModuleWithTests.TestClassName testMethodName]' failed (22.128 seconds).
                """,
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.accumulatedData,
            [
                Either.left(
                    TestName(className: "TestClassName", methodName: "testMethodName")
                ),
                Either.left(
                    TestName(className: "TestClassName", methodName: "testAnother")
                ),
                Either.right(
                    TestStoppedEvent(
                        testName: TestName(className: "TestClassName", methodName: "testMethodName"),
                        result: .failure,
                        testDuration: 22.128,
                        testExceptions: [],
                        testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
                    )
                )
            ]
        )
    }
}
