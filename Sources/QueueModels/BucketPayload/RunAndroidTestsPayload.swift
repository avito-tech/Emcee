import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import TestDestination

public struct RunAndroidTestsPayload: BucketPayload, CustomStringConvertible, BucketPayloadWithTests {
    public let buildArtifacts: AndroidBuildArtifacts
    public let testDestination: AppleTestDestination
    public private(set) var testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration

    public init(
        buildArtifacts: AndroidBuildArtifacts,
        testDestination: AppleTestDestination,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration
    ) {
        self.buildArtifacts = buildArtifacts
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
    }

    public var description: String {
        "run \(testEntries.count) tests: \(testEntries.map { $0.testName.stringValue }.joined(separator: ", "))"
    }

    public func with(testEntries newTestEntries: [TestEntry]) -> Self {
        var result = self
        result.testEntries = newTestEntries
        return result
    }
}
