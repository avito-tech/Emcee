import AndroidEmulatorModels
import BuildArtifacts
import Foundation
import RunnerModels
import TestDestination

public struct RunAndroidTestsPayload: BucketPayload, CustomStringConvertible, BucketPayloadWithTests {
    public let buildArtifacts: AndroidBuildArtifacts
    public let deviceType: String
    public let sdkVersion: Int
    public private(set) var testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testMaximumDuration: TimeInterval

    public init(
        buildArtifacts: AndroidBuildArtifacts,
        deviceType: String,
        sdkVersion: Int,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testMaximumDuration: TimeInterval
    ) {
        self.buildArtifacts = buildArtifacts
        self.deviceType = deviceType
        self.sdkVersion = sdkVersion
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testMaximumDuration = testMaximumDuration
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
        TestDestination.androidEmulator(deviceType: deviceType, sdkVersion: sdkVersion)
    }
}
