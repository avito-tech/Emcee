import Foundation
import Runner

public final class FbXcTestStartedEvent: CustomStringConvertible, CommonTestFields, Codable {
    public let event: FbXcTestEventName = .testStarted
    public let test: String          // e.g. -[FunctionalTests.MainPageTest test_dataSet0]
    private let className: String     // e.g. FunctionalTests.MainPageTest
    private let methodName: String    // test_dataSet0
    public let timestamp: TimeInterval
    
    public init(
        test: String,
        className: String,
        methodName: String,
        timestamp: TimeInterval
    ) {
        self.test = test
        self.className = className
        self.methodName = methodName
        self.timestamp = timestamp
    }
    
    public var testClassName: String {
        return TestNameParser.className(moduledClassName: className)
    }
    
    public var testMethodName: String {
        return methodName
    }
    
    public var testModuleName: String {
        return TestNameParser.moduleName(moduledClassName: className)
    }
    
    public var description: String {
        return "Started test \(testName)"
    }
}
