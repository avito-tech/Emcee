import Foundation

public final class FbXcTestFinishedEvent: CustomStringConvertible, CommonTestFields, Codable {
    public let event: FbXcTestEventName = .testFinished
    public let test: String            // e.g. -[FunctionalTests.MainPageTest_100856 test_dataSet0]
    public let result: String          // e.g. "success" or "failure"
    private let className: String       // e.g. FunctionalTests.MainPageTest_100856
    private let methodName: String      // e.g. test_dataSet0
    public let totalDuration: TimeInterval
    public let exceptions: [FbXcTestExceptionEvent]
    public let succeeded: Bool
    public let output: String
    public let logs: [String]
    public let timestamp: TimeInterval
    
    public init(
        test: String,
        result: String,
        className: String,
        methodName: String,
        totalDuration: TimeInterval,
        exceptions: [FbXcTestExceptionEvent],
        succeeded: Bool,
        output: String,
        logs: [String],
        timestamp: TimeInterval
    ) {
        self.test = test
        self.result = result
        self.className = className
        self.methodName = methodName
        self.totalDuration = totalDuration
        self.exceptions = exceptions
        self.succeeded = succeeded
        self.output = output
        self.logs = logs
        self.timestamp = timestamp
    }
    
    public var testClassName: String {
        return FbXcTestEventClassNameParser.className(moduledClassName: className)
    }
    
    public var testMethodName: String {
        return methodName
    }
    
    public var testModuleName: String {
        return FbXcTestEventClassNameParser.moduleName(moduledClassName: className)
    }
    
    public var description: String {
        return "Finished test \(testName), " +
            (succeeded
                ? "test passed".with(consoleColor: .boldGreen)
                : "test failed".with(consoleColor: .boldRed)) +
        ", \(Int(totalDuration)) sec"
    }
}
