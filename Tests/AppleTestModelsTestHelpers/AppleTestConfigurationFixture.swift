import AppleTestModels
import BuildArtifacts
import BuildArtifactsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import DeveloperDirModels
import Foundation
import PluginSupport
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import BuildArtifactsTestHelpers

public final class AppleTestConfigurationFixture {
    
    public var buildArtifacts: AppleBuildArtifacts
    public var developerDir: DeveloperDir
    public var pluginLocations: Set<AppleTestPluginLocation>
    public var simulatorOperationTimeouts: SimulatorOperationTimeouts
    public var simulatorSettings: SimulatorSettings
    public var simDeviceType: SimDeviceType
    public var simRuntime: SimRuntime
    public var testExecutionBehavior: TestExecutionBehavior
    public var testTimeoutConfiguration: TestTimeoutConfiguration
    public var testAttachmentLifetime: TestAttachmentLifetime
    public var collectResultBundles: Bool
    
    public init(
        buildArtifacts: AppleBuildArtifacts = AppleBuildArtifactsFixture().appleBuildArtifacts(),
        developerDir: DeveloperDir = .current,
        pluginLocations: Set<AppleTestPluginLocation> = [],
        simulatorOperationTimeouts: SimulatorOperationTimeouts = SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
        simulatorSettings: SimulatorSettings = SimulatorSettingsFixtures().simulatorSettings(),
        simDeviceType: SimDeviceType = SimDeviceTypeFixture.fixture(),
        simRuntime: SimRuntime = SimRuntimeFixture.fixture(),
        testExecutionBehavior: TestExecutionBehavior = TestExecutionBehaviorFixtures().testExecutionBehavior(),
        testTimeoutConfiguration: TestTimeoutConfiguration = TestTimeoutConfiguration(singleTestMaximumDuration: 60, testRunnerMaximumSilenceDuration: 60),
        testAttachmentLifetime: TestAttachmentLifetime = .deleteOnSuccess,
        collectResultBundles: Bool = false
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
        self.collectResultBundles = collectResultBundles
    }
    
    public func with(buildArtifacts: AppleBuildArtifacts) -> Self {
        self.buildArtifacts = buildArtifacts
        return self
    }
    
    public func with(developerDir: DeveloperDir) -> Self {
        self.developerDir = developerDir
        return self
    }
    
    public func with(pluginLocations: Set<AppleTestPluginLocation>) -> Self {
        self.pluginLocations = pluginLocations
        return self
    }
    
    public func with(simulatorOperationTimeouts: SimulatorOperationTimeouts) -> Self {
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        return self
    }
    
    public func with(simulatorSettings: SimulatorSettings) -> Self {
        self.simulatorSettings = simulatorSettings
        return self
    }
    
    public func with(simDeviceType: SimDeviceType) -> Self {
        self.simDeviceType = simDeviceType
        return self
    }
    
    public func with(simRuntime: SimRuntime) -> Self {
        self.simRuntime = simRuntime
        return self
    }
    
    public func with(testExecutionBehavior: TestExecutionBehavior) -> Self {
        self.testExecutionBehavior = testExecutionBehavior
        return self
    }
    
    public func with(testTimeoutConfiguration: TestTimeoutConfiguration) -> Self {
        self.testTimeoutConfiguration = testTimeoutConfiguration
        return self
    }
    
    public func with(testAttachmentLifetime: TestAttachmentLifetime) -> Self {
        self.testAttachmentLifetime = testAttachmentLifetime
        return self
    }
    
    public func with(collectResultBundles: Bool) -> Self {
        self.collectResultBundles = collectResultBundles
        return self
    }
    
    public func appleTestConfiguration() -> AppleTestConfiguration {
        AppleTestConfiguration(
            buildArtifacts: buildArtifacts,
            developerDir: developerDir,
            pluginLocations: pluginLocations,
            simulatorOperationTimeouts: simulatorOperationTimeouts,
            simulatorSettings: simulatorSettings,
            simDeviceType: simDeviceType,
            simRuntime: simRuntime,
            testExecutionBehavior: testExecutionBehavior,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testAttachmentLifetime: testAttachmentLifetime,
            resultBundlesUrl: nil
        )
    }
}
