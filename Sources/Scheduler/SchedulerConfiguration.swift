import EventBus
import Foundation
import Models
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    public let schedulerDataSource: SchedulerDataSource
    public let onDemandSimulatorPool: OnDemandSimulatorPool

    public init(
        testRunExecutionBehavior: TestRunExecutionBehavior,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool
    ) {
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.schedulerDataSource = schedulerDataSource
        self.onDemandSimulatorPool = onDemandSimulatorPool
    }
}
