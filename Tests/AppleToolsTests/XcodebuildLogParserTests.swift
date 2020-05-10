import AppleTools
import DateProvider
import DateProviderTestHelpers
import Foundation
import Models
import Runner
import RunnerModels
import RunnerTestHelpers
import TestHelpers
import XCTest

final class XcodebuildLogParserTests: XCTestCase {
    private let dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    private let accumulatingTestRunnerStream = AccumulatingTestRunnerStream()
    private lazy var parser = assertDoesNotThrow {
        try XcodebuildLogParser(dateProvider: dateProvider)
    }
    
    func test___parsing_unrelated_string___produces_no_event() {
        assertDoesNotThrow {
            try parser.parse(string: "", testRunnerStream: accumulatingTestRunnerStream)
            try parser.parse(string: "abc", testRunnerStream: accumulatingTestRunnerStream)
        }
        
        XCTAssertTrue(accumulatingTestRunnerStream.accumulatedData.isEmpty)
    }
    
    func test___parsing_test_start___produces_test_start_event() {
        assertDoesNotThrow {
            try parser.parse(
                string: "Test Case '-[ModuleWithTests.TestClassName testMethodName]' started.",
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        if accumulatingTestRunnerStream.accumulatedData.count != 1 {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestName.self, index: 0),
            TestName(className: "TestClassName", methodName: "testMethodName")
        )
    }
    
    func test___parsing_test_passed____produces_test_stopped_event() {
        assertDoesNotThrow {
            try parser.parse(
                string: "Test Case '-[UITests.SomeTest_1234 test]' passed (22.128 seconds).",
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        if accumulatingTestRunnerStream.accumulatedData.count != 1 {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestStoppedEvent.self, index: 0),
            TestStoppedEvent(
                testName: TestName(className: "SomeTest_1234", methodName: "test"),
                result: .success,
                testDuration: 22.128,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
            )
        )
    }
    
    func test___parsing_test_failed____produces_test_stopped_event() {
        assertDoesNotThrow {
            try parser.parse(
                string: "Test Case '-[UITests.SomeTest_1234 test]' failed (22.128 seconds).",
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        if accumulatingTestRunnerStream.accumulatedData.count != 1 {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestStoppedEvent.self, index: 0),
            TestStoppedEvent(
                testName: TestName(className: "SomeTest_1234", methodName: "test"),
                result: .failure,
                testDuration: 22.128,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
            )
        )
    }
    
    func test___parsing_errors() {
        assertDoesNotThrow {
            try parser.parse(
                string: """
                /path/to/source_file.swift:100: error: -[ModuleWithTests.TestClassName testMethodName] : XCTAssertEqual failed: ("24") is not equal to ("42")
                """,
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        guard accumulatingTestRunnerStream.accumulatedData.count == 1 else {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestException.self, index: 0),
            TestException(
                reason: "XCTAssertEqual failed: (\"24\") is not equal to (\"42\")",
                filePathInProject: "/path/to/source_file.swift",
                lineNumber: 100
            )
        )
    }
    
    func test___parsing_multiline_string() {
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
        
        if accumulatingTestRunnerStream.accumulatedData.count != 3 {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestName.self, index: 0),
            TestName(className: "TestClassName", methodName: "testMethodName")
        )
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestName.self, index: 1),
            TestName(className: "TestClassName", methodName: "testAnother")
        )
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestStoppedEvent.self, index: 2),
            TestStoppedEvent(
                testName: TestName(className: "TestClassName", methodName: "testMethodName"),
                result: .failure,
                testDuration: 22.128,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
            )
        )
    }
    
    func test___order_of_multiline_string_parsing() {
        assertDoesNotThrow {
            try parser.parse(
                string: """
                /path/to/source_file.swift:100: error: -[ModuleWithTests.TestClassName testMethodName] : some reason
                Test Case '-[ModuleWithTests.TestClassName testMethodName]' failed (22.128 seconds).
                Test Case '-[ModuleWithTests.TestClassName testAnother]' started.
                """,
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        if accumulatingTestRunnerStream.accumulatedData.count != 3 {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestException.self, index: 0),
            TestException(reason: "some reason", filePathInProject: "/path/to/source_file.swift", lineNumber: 100)
        )
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestStoppedEvent.self, index: 1),
            TestStoppedEvent(
                testName: TestName(className: "TestClassName", methodName: "testMethodName"),
                result: .failure,
                testDuration: 22.128,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-22.128).timeIntervalSince1970
            )
        )
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestName.self, index: 2),
            TestName(className: "TestClassName", methodName: "testAnother")
        )
    }
}
