import AutomaticTermination
import Foundation
import Models

public struct QueueServerRunConfiguration: Decodable {
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
    
    /// Some settings that should be applied to the test environment prior running the tests
    public let simulatorSettings: SimulatorSettings
    
    /// Timeout values.
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /// Schedule strategy on worker
    public let workerScheduleStrategy: ScheduleStrategyType

    public init(auxiliaryResources: AuxiliaryResources, checkAgainTimeInterval: TimeInterval, deploymentDestinationConfigurations: [DestinationConfiguration], queueServerTerminationPolicy: AutomaticTerminationPolicy, remoteScheduleStrategyType: ScheduleStrategyType, reportAliveInterval: TimeInterval, simulatorSettings: SimulatorSettings, testTimeoutConfiguration: TestTimeoutConfiguration, workerScheduleStrategy: ScheduleStrategyType) {
        self.auxiliaryResources = auxiliaryResources
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.deploymentDestinationConfigurations = deploymentDestinationConfigurations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.remoteScheduleStrategyType = remoteScheduleStrategyType
        self.reportAliveInterval = reportAliveInterval
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.workerScheduleStrategy = workerScheduleStrategy
    }
    
    public func workerConfiguration(
        deploymentDestinationConfiguration: DestinationConfiguration)
        -> WorkerConfiguration
    {
        return WorkerConfiguration(
            testRunExecutionBehavior: testRunExecutionBehavior(
                deploymentDestinationConfiguration: deploymentDestinationConfiguration
            ),
            testTimeoutConfiguration: testTimeoutConfiguration,
            pluginUrls: auxiliaryResources.plugins.compactMap { $0.resourceLocation.url },
            reportAliveInterval: reportAliveInterval
        )
    }
    
    private func testRunExecutionBehavior(
        deploymentDestinationConfiguration: DestinationConfiguration)
        -> TestRunExecutionBehavior
    {
        // Queue server will retry by itself, workers should not attempt to retry failed tests
        let numberOfRetriesOnLocalMachine: UInt = 0
        
        return TestRunExecutionBehavior(
            numberOfRetries: numberOfRetriesOnLocalMachine,
            numberOfSimulators: deploymentDestinationConfiguration.numberOfSimulators,
            environment: [:],
            scheduleStrategy: workerScheduleStrategy
        )
    }
}
