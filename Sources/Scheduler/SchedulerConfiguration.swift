import EventBus
import Foundation
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let numberOfSimulators: UInt
    public let schedulerDataSource: SchedulerDataSource

    public init(
        numberOfSimulators: UInt,
        schedulerDataSource: SchedulerDataSource
    ) {
        self.numberOfSimulators = numberOfSimulators
        self.schedulerDataSource = schedulerDataSource
    }
}
