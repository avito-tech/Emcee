import AndroidTestModels
import CommonTestModels
import Foundation
import TestDestination

public struct RunAndroidTestsPayload: BucketPayload, CustomStringConvertible, BucketPayloadWithTests {
    public private(set) var testEntries: [TestEntry]
    public let testConfiguration: AndroidTestConfiguration

    public init(
        testEntries: [TestEntry],
        testConfiguration: AndroidTestConfiguration
    ) {
        self.testEntries = testEntries
        self.testConfiguration = testConfiguration
    }

    public var description: String {
        "run \(testEntries.count) tests: \(testEntries.map { $0.testName.stringValue }.joined(separator: ", "))"
    }

    public func with(testEntries newTestEntries: [TestEntry]) -> Self {
        var result = self
        result.testEntries = newTestEntries
        return result
    }
    
    public var testDestination: TestDestination {
        testConfiguration.testDestination
    }
    
    public var testExecutionBehavior: TestExecutionBehavior {
        testConfiguration.testExecutionBehavior
    }
}
