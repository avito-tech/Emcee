import AppleTools
import Foundation
import Runner

public final class FakeXcodebuildLogParser: XcodebuildLogParser {
    private let testRunnerStream: TestRunnerStream
    
    public init(testRunnerStream: TestRunnerStream) {
        self.testRunnerStream = testRunnerStream
    }
    
    public var onEvent: (String, TestRunnerStream) throws -> () = { _, _ in }
    
    public func parse(string: String, testRunnerStream: TestRunnerStream) throws {
        try onEvent(string, testRunnerStream)
    }
}
