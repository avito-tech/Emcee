import AutomaticTermination
import Foundation
import Models

public struct QueueServerRunConfiguration: Decodable {
    public let analyticsConfiguration: AnalyticsConfiguration
    
    /// Paths that are required to make things work
    public let auxiliaryResources: AuxiliaryResources

    /// Delay after workers should ask for a next bucket when all jobs are depleted
    public let checkAgainTimeInterval: TimeInterval
    
    /// A list of additional per-destination configurations.
    public let deploymentDestinationConfigurations: [DestinationConfiguration]
    
    /// Defines when queue server will terminate itself.
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    
    /// Period of time when workers should report their aliveness
    public let reportAliveInterval: TimeInterval
    
    /// Some settings that should be applied to the test environment prior running the tests
    public let simulatorSettings: SimulatorSettings
    
    /// Timeout values.
    public let testTimeoutConfiguration: TestTimeoutConfiguration

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        auxiliaryResources: AuxiliaryResources,
        checkAgainTimeInterval: TimeInterval,
        deploymentDestinationConfigurations: [DestinationConfiguration],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        reportAliveInterval: TimeInterval,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.auxiliaryResources = auxiliaryResources
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.deploymentDestinationConfigurations = deploymentDestinationConfigurations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.reportAliveInterval = reportAliveInterval
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
    }
    
    public func workerConfiguration(
        deploymentDestinationConfiguration: DestinationConfiguration,
        requestSignature: RequestSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            testRunExecutionBehavior: testRunExecutionBehavior(
                deploymentDestinationConfiguration: deploymentDestinationConfiguration
            ),
            testTimeoutConfiguration: testTimeoutConfiguration,
            pluginUrls: auxiliaryResources.plugins.compactMap { $0.resourceLocation.url },
            reportAliveInterval: reportAliveInterval,
            requestSignature: requestSignature
        )
    }
    
    private func testRunExecutionBehavior(
        deploymentDestinationConfiguration: DestinationConfiguration
    ) -> TestRunExecutionBehavior {
        return TestRunExecutionBehavior(
            numberOfSimulators: deploymentDestinationConfiguration.numberOfSimulators
        )
    }
}
