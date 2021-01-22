import DateProvider
import Foundation
import Runner
import RunnerModels
import XCTestJsonCodable

public final class XCTestJsonParser: XcodebuildLogParser {
    private let dateProvider: DateProvider
    
    public init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
    }
    
    public func parse(
        string: String,
        testRunnerStream: TestRunnerStream
    ) throws {
        string
            .split(separator: "\n")
            .filter { $0.starts(with: "{") }
            .compactMap { json in
                try? JSONDecoder().decode(
                    XCTestJsonEvent.self,
                    from: Data(json.utf8)
                )
            }
            .forEach { event in
                switch event {
                case .beginTest(let startEvent):
                    testRunnerStream.testStarted(
                        testName: TestName(
                            className: startEvent.className,
                            methodName: startEvent.methodName
                        )
                    )
                case .testFailure(let event):
                    testRunnerStream.caughtException(
                        testException: TestException(
                            reason: event.reason,
                            filePathInProject: event.file,
                            lineNumber: Int32(event.line)
                        )
                    )
                case .endTest(let endEvent):
                    let result: TestStoppedEvent.Result
                    switch endEvent.result {
                    case .error: result = .lost
                    case .failure: result = .failure
                    case .success: result = .success
                    }
                    
                    testRunnerStream.testStopped(
                        testStoppedEvent: TestStoppedEvent(
                            testName: TestName(
                                className: endEvent.className,
                                methodName: endEvent.methodName
                            ),
                            result: result,
                            testDuration: endEvent.totalDuration,
                            testExceptions: [],
                            testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970 - endEvent.totalDuration
                        )
                    )
                }
            }
    }
}
