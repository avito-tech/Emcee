import AppleTestModels
import BuildArtifacts
import CommonTestModels
import DeveloperDirModels
import EmceeLogging
import Foundation
import MetricsExtensions
import PluginSupport
import SimulatorPoolModels
import TestArgFile

public struct TestDiscoveryConfiguration {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let logger: ContextualLogger
    public let remoteCache: RuntimeDumpRemoteCache
    public let testsToValidate: [TestToRun]
    public let testDiscoveryMode: TestDiscoveryMode
    public let testConfiguration: AppleTestConfiguration

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        logger: ContextualLogger,
        remoteCache: RuntimeDumpRemoteCache,
        testsToValidate: [TestToRun],
        testDiscoveryMode: TestDiscoveryMode,
        testConfiguration: AppleTestConfiguration
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.logger = logger
        self.remoteCache = remoteCache
        self.testsToValidate = testsToValidate
        self.testDiscoveryMode = testDiscoveryMode
        self.testConfiguration = testConfiguration
    }
}
