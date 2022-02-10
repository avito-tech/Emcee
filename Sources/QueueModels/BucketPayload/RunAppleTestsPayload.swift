import AppleTestModels
import CommonTestModels
import Foundation
import TestDestination

public struct RunAppleTestsPayload: BucketPayload, CustomStringConvertible, BucketPayloadWithTests {
    public private(set) var testEntries: [TestEntry]
    public let testsConfiguration: AppleTestConfiguration

    public init(
        testEntries: [TestEntry],
        testsConfiguration: AppleTestConfiguration
    ) {
        self.testEntries = testEntries
        self.testsConfiguration = testsConfiguration
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
        testsConfiguration.testDestination
    }
    
    public var testExecutionBehavior: TestExecutionBehavior {
        testsConfiguration.testExecutionBehavior
    }
}
