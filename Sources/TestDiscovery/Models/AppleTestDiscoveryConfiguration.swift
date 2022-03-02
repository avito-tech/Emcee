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

public struct AppleTestDiscoveryConfiguration: TestDiscoveryConfiguration {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let remoteCache: RuntimeDumpRemoteCache
    public let testsToValidate: [TestToRun]
    public let testDiscoveryMode: AppleTestDiscoveryMode
    public let testConfiguration: AppleTestConfiguration

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        remoteCache: RuntimeDumpRemoteCache,
        testsToValidate: [TestToRun],
        testDiscoveryMode: AppleTestDiscoveryMode,
        testConfiguration: AppleTestConfiguration
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.remoteCache = remoteCache
        self.testsToValidate = testsToValidate
        self.testDiscoveryMode = testDiscoveryMode
        self.testConfiguration = testConfiguration
    }
}
