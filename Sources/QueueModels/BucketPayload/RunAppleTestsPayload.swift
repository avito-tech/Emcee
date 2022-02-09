import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import TestDestination

public struct RunAppleTestsPayload: BucketPayload, CustomStringConvertible, BucketPayloadWithTests {
    public let buildArtifacts: AppleBuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<AppleTestPluginLocation>
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let simDeviceType: SimDeviceType
    public let simRuntime: SimRuntime
    public private(set) var testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testAttachmentLifetime: TestAttachmentLifetime

    public init(
        buildArtifacts: AppleBuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<AppleTestPluginLocation>,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testAttachmentLifetime: TestAttachmentLifetime
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.simDeviceType = simDeviceType
        self.simRuntime = simRuntime
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testAttachmentLifetime = testAttachmentLifetime
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
        TestDestination.appleSimulator(
            simDeviceType: simDeviceType,
            simRuntime: simRuntime
        )
    }
}
