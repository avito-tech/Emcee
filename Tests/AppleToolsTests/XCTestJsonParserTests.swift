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

final class XCTesttJsonParserTests: XCTestCase {
    private let dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    private let accumulatingTestRunnerStream = AccumulatingTestRunnerStream()
    private lazy var parser = XCTestJsonParser(dateProvider: self.dateProvider)
    
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
                string:
                """
                {"beginTest":{"className":"TestClassName","methodName":"testMethodName"}}
                """,
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
                string:
                """
                {"endTest":{"result":"success","className":"SomeTest_1234","methodName":"test","totalDuration":22.128,"failures":[]}}
                """,
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
                string:
                """
                {"endTest":{"result":"failure","className":"SomeTest_1234","methodName":"test","totalDuration":22.128,"failures":[]}}
                """,
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
                string:
                """
                {"endTest":{"result":"failure","className":"Tests","failures":[{"line":100,"file":"\\/path\\/to\\/source_file.swift","reason":"XCTAssertEqual failed: (\\"24\\") is not equal to (\\"42\\")"}],"methodName":"test","totalDuration":1}}
                """,
                testRunnerStream: accumulatingTestRunnerStream
            )
        }
        
        guard accumulatingTestRunnerStream.accumulatedData.count == 1 else {
            failTest("Unexpected number of captured events")
        }
        
        XCTAssertEqual(
            accumulatingTestRunnerStream.castTo(TestStoppedEvent.self, index: 0),
            TestStoppedEvent(
                testName: TestName(
                    className: "Tests",
                    methodName: "test"
                ),
                result: .failure,
                testDuration: 1,
                testExceptions: [
                    TestException(
                        reason: "XCTAssertEqual failed: (\"24\") is not equal to (\"42\")",
                        filePathInProject: "/path/to/source_file.swift",
                        lineNumber: 100
                    )
                ],
                testStartTimestamp: 99
            )
        )
    }
    
    func test___parsing_multiline_string() {
        assertDoesNotThrow {
            try parser.parse(
                string: """
                {"beginTest":{"className":"TestClassName","methodName":"testMethodName"}}
                {"beginTest":{"className":"TestClassName","methodName":"testAnother"}}
                {"endTest":{"result":"failure","className":"TestClassName","methodName":"testMethodName","totalDuration":22.128,"failures":[]}}
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
    
    func test___parsing_multiline_string___with_other_output_in_stdout() {
        assertDoesNotThrow {
            try parser.parse(
                string: """
                {"beginTest":{"className":"TestClassName","methodName":"testMethodName"}}
                {{}}
                hello world
                {"beginTest":{"className":"TestClassName","methodName":"testAnother"}}
                {"endTest":{"result":"failure","className":"TestClassName","methodName":"testMethodName","totalDuration":22.128,"failures":[]}}
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
}
