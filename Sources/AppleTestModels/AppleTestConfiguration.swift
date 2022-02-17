import BuildArtifacts
import CommonTestModels
import DeveloperDirModels
import Foundation
import PluginSupport
import SimulatorPoolModels
import TestDestination

public final class AppleTestConfiguration: Codable, Hashable {
    public let buildArtifacts: AppleBuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<AppleTestPluginLocation>
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let simDeviceType: SimDeviceType
    public let simRuntime: SimRuntime
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
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testAttachmentLifetime = testAttachmentLifetime
    }
    
    public var onDemandSimulatorPoolKey: OnDemandSimulatorPoolKey {
        OnDemandSimulatorPoolKey(
            developerDir: developerDir,
            simDeviceType: simDeviceType,
            simRuntime: simRuntime
        )
    }
    
    public var testDestination: TestDestination {
        TestDestination.appleSimulator(
            simDeviceType: simDeviceType,
            simRuntime: simRuntime
        )
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(buildArtifacts)
        hasher.combine(developerDir)
        hasher.combine(pluginLocations)
        hasher.combine(simulatorOperationTimeouts)
        hasher.combine(simulatorSettings)
        hasher.combine(simDeviceType)
        hasher.combine(simRuntime)
        hasher.combine(testExecutionBehavior)
        hasher.combine(testTimeoutConfiguration)
        hasher.combine(testAttachmentLifetime)
    }
    
    public static func == (lhs: AppleTestConfiguration, rhs: AppleTestConfiguration) -> Bool {
        return true
        && lhs.buildArtifacts == rhs.buildArtifacts
        && lhs.developerDir == rhs.developerDir
        && lhs.pluginLocations == rhs.pluginLocations
        && lhs.simulatorOperationTimeouts == rhs.simulatorOperationTimeouts
        && lhs.simulatorSettings == rhs.simulatorSettings
        && lhs.simDeviceType == rhs.simDeviceType
        && lhs.simRuntime == rhs.simRuntime
        && lhs.testExecutionBehavior == rhs.testExecutionBehavior
        && lhs.testTimeoutConfiguration == rhs.testTimeoutConfiguration
        && lhs.testAttachmentLifetime == rhs.testAttachmentLifetime
    }
}
