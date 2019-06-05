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
    
    /// How to scatter tests onto destinations.
    public let remoteScheduleStrategyType: ScheduleStrategyType
    
    /// Period of time when workers should report their aliveness
    public let reportAliveInterval: TimeInterval

    /// A signature that workers are expected to use to send their requests to the queue.
    public let requestSignature: RequestSignature
    
    /// Some settings that should be applied to the test environment prior running the tests
    public let simulatorSettings: SimulatorSettings
    
    /// Timeout values.
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /// Schedule strategy on worker
    public let workerScheduleStrategy: ScheduleStrategyType

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        auxiliaryResources: AuxiliaryResources,
        checkAgainTimeInterval: TimeInterval,
        deploymentDestinationConfigurations: [DestinationConfiguration],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        remoteScheduleStrategyType: ScheduleStrategyType,
        reportAliveInterval: TimeInterval,
        requestSignature: RequestSignature,
        simulatorSettings: SimulatorSettings,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        workerScheduleStrategy: ScheduleStrategyType
        )
    {
        self.analyticsConfiguration = analyticsConfiguration
        self.auxiliaryResources = auxiliaryResources
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.deploymentDestinationConfigurations = deploymentDestinationConfigurations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.remoteScheduleStrategyType = remoteScheduleStrategyType
        self.reportAliveInterval = reportAliveInterval
        self.requestSignature = requestSignature
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.workerScheduleStrategy = workerScheduleStrategy
    }
    
    public func workerConfiguration(
        deploymentDestinationConfiguration: DestinationConfiguration
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
            numberOfSimulators: deploymentDestinationConfiguration.numberOfSimulators,
            scheduleStrategy: workerScheduleStrategy
        )
    }
}
