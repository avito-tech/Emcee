import EventBus
import Foundation
import Models
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let numberOfSimulators: UInt
    public let onDemandSimulatorPool: OnDemandSimulatorPool
    public let schedulerDataSource: SchedulerDataSource

    public init(
        numberOfSimulators: UInt,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        schedulerDataSource: SchedulerDataSource
    ) {
        self.numberOfSimulators = numberOfSimulators
        self.schedulerDataSource = schedulerDataSource
        self.onDemandSimulatorPool = onDemandSimulatorPool
    }
}
