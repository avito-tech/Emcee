import DateProviderTestHelpers
import Foundation
import TestHelpers
import ResultStream
import ResultStreamModels
import RunnerModels
import RunnerTestHelpers
import SynchronousWaiter
import XCTest

final class ResultStreamTests: XCTestCase {
    func test() throws {
        let streamContents = """
        {"_type":{"_name":"StreamedEvent"},"name":{"_type":{"_name":"String"},"_value":"testStarted"},"structuredPayload":{"_type":{"_name":"TestEventPayload","_supertype":{"_name":"AnyStreamedEventPayload"}},"resultInfo":{"_type":{"_name":"StreamedActionResultInfo"},"resultIndex":{"_type":{"_name":"Int"},"_value":"1"}},"testIdentifier":{"_type":{"_name":"ActionTestSummaryIdentifiableObject","_supertype":{"_name":"ActionAbstractTestSummary"}},"identifier":{"_type":{"_name":"String"},"_value":"ClassName\\/test()"},"name":{"_type":{"_name":"String"},"_value":"test()"}}}}
        {"_type":{"_name":"StreamedEvent"},"name":{"_type":{"_name":"String"},"_value":"issueEmitted"},"structuredPayload":{"_type":{"_name":"IssueEmittedEventPayload","_supertype":{"_name":"AnyStreamedEventPayload"}},"issue":{"_type":{"_name":"TestFailureIssueSummary","_supertype":{"_name":"IssueSummary"}},"documentLocationInCreatingWorkspace":{"_type":{"_name":"DocumentLocation"},"concreteTypeName":{"_type":{"_name":"String"},"_value":"DVTTextDocumentLocation"},"url":{"_type":{"_name":"String"},"_value":"file:\\/\\/\\/path/to/file.swift#CharacterRangeLen=0&EndingLineNumber=110&StartingLineNumber=110"}},"issueType":{"_type":{"_name":"String"},"_value":"Uncategorized"},"message":{"_type":{"_name":"String"},"_value":"\\"проверить, что отображается \\"Экран\\"\\" неуспешно, так как: элемент не найден в иерархии"},"testCaseName":{"_type":{"_name":"String"},"_value":"TRF_ActivationRejected_SinglePlusVas.test()"}},"resultInfo":{"_type":{"_name":"StreamedActionResultInfo"},"resultIndex":{"_type":{"_name":"Int"},"_value":"1"}},"severity":{"_type":{"_name":"String"},"_value":"testFailure"}}}
        {"_type":{"_name":"StreamedEvent"},"name":{"_type":{"_name":"String"},"_value":"testFinished"},"structuredPayload":{"_type":{"_name":"TestFinishedEventPayload","_supertype":{"_name":"AnyStreamedEventPayload"}},"resultInfo":{"_type":{"_name":"StreamedActionResultInfo"},"resultIndex":{"_type":{"_name":"Int"},"_value":"1"}},"test":{"_type":{"_name":"ActionTestMetadata","_supertype":{"_name":"ActionTestSummaryIdentifiableObject","_supertype":{"_name":"ActionAbstractTestSummary"}}},"duration":{"_type":{"_name":"Double"},"_value":"7.6910330057144165"},"identifier":{"_type":{"_name":"String"},"_value":"ClassName\\/test()"},"name":{"_type":{"_name":"String"},"_value":"test()"},"testStatus":{"_type":{"_name":"String"},"_value":"Success"}}}}
        """

        let stream = resultStream(with: streamContents)
        wait(for: [stream.streamFinishedExpectation()], timeout: 15)
        
        XCTAssertEqual(
            testRunnerStream.castTo(TestName.self, index: 0),
            TestName(className: "ClassName", methodName: "test")
        )
        XCTAssertEqual(
            testRunnerStream.castTo(TestException.self, index: 1),
            TestException(
                reason: "\"проверить, что отображается \"Экран\"\" неуспешно, так как: элемент не найден в иерархии",
                filePathInProject: "/path/to/file.swift",
                lineNumber: 110
            )
        )
        XCTAssertEqual(
            testRunnerStream.castTo(TestStoppedEvent.self, index: 2),
            TestStoppedEvent(
                testName: TestName(className: "ClassName", methodName: "test"),
                result: .success,
                testDuration: 7.6910330057144165,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970 - 7.6910330057144165
            )
        )
    }
    
    func test___parsing_cyrillic() throws {
        let streamContents = """
        {"_type":{"_name":"StreamedEvent"},"name":{"_type":{"_name":"String"},"_value":"testStarted"},"structuredPayload":{"_type":{"_name":"TestEventPayload","_supertype":{"_name":"AnyStreamedEventPayload"}},"resultInfo":{"_type":{"_name":"StreamedActionResultInfo"},"resultIndex":{"_type":{"_name":"Int"},"_value":"1"}},"testIdentifier":{"_type":{"_name":"ActionTestSummaryIdentifiableObject","_supertype":{"_name":"ActionAbstractTestSummary"}},"identifier":{"_type":{"_name":"String"},"_value":"ClassName\\/привет()"},"name":{"_type":{"_name":"String"},"_value":"привет()"}}}}
        """

        let stream = resultStream(with: streamContents)
        wait(for: [stream.streamFinishedExpectation()], timeout: 15)
        
        XCTAssertEqual(
            testRunnerStream.castTo(TestName.self, index: 0),
            TestName(className: "ClassName", methodName: "привет")
        )
    }
    
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    lazy var testRunnerStream = AccumulatingTestRunnerStream()
    
    private func resultStream(with contents: String) -> ResultStream {
        let stream = ResultStreamImpl(
            dateProvider: dateProvider,
            logger: .noOp,
            testRunnerStream: testRunnerStream
        )
        stream.write(data: contents.data(using: .utf8) ?? Data())
        stream.close()
        return stream
    }
}

private extension ResultStream {
    func streamFinishedExpectation() -> XCTestExpectation {
        let streamFinishedExpectation = XCTestExpectation(description: "")
        streamContents { error in
            XCTAssertNil(error, "Unexpected error: \(String(describing: error))")
            streamFinishedExpectation.fulfill()
        }
        return streamFinishedExpectation
    }
}
