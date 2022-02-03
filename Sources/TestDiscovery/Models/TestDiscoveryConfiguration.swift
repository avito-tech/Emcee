import BuildArtifacts
import DeveloperDirModels
import EmceeLogging
import Foundation
import MetricsExtensions
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import TestArgFile
import TestDestination

public struct TestDiscoveryConfiguration {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let testDiscoveryMode: TestDiscoveryMode
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testAttachmentLifetime: TestAttachmentLifetime
    public let testsToValidate: [TestToRun]
    public let xcTestBundleLocation: TestBundleLocation
    public let remoteCache: RuntimeDumpRemoteCache
    public let logger: ContextualLogger

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        testDiscoveryMode: TestDiscoveryMode,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testAttachmentLifetime: TestAttachmentLifetime,
        testsToValidate: [TestToRun],
        xcTestBundleLocation: TestBundleLocation,
        remoteCache: RuntimeDumpRemoteCache,
        logger: ContextualLogger
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.testDiscoveryMode = testDiscoveryMode
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testAttachmentLifetime = testAttachmentLifetime
        self.testsToValidate = testsToValidate
        self.xcTestBundleLocation = xcTestBundleLocation
        self.remoteCache = remoteCache
        self.logger = logger
    }
}
