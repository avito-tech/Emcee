import EventBus
import Foundation
import Models
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let testType: TestType
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let schedulerDataSource: SchedulerDataSource
    public let onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>
    
    public func runnerConfiguration(
        fbxctest: FbxctestLocation,
        buildArtifacts: BuildArtifacts,
        simulatorSettings: SimulatorSettings
        ) -> RunnerConfiguration
    {
        return RunnerConfiguration(
            testType: testType,
            fbxctest: fbxctest,
            buildArtifacts: buildArtifacts,
            testRunExecutionBehavior: testRunExecutionBehavior,
            simulatorSettings: simulatorSettings,
            testTimeoutConfiguration: testTimeoutConfiguration
        )
    }

    public init(
        testType: TestType,
        testRunExecutionBehavior: TestRunExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>)
    {
        self.testType = testType
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.schedulerDataSource = schedulerDataSource
        self.onDemandSimulatorPool = onDemandSimulatorPool
    }
}
