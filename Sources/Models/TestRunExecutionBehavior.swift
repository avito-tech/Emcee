import Foundation

/** Defines the specifics of the behavior of the test run. */
public struct TestRunExecutionBehavior: Codable, Equatable {
    
    /** Maximum number of simulators to create and use in parallel. */
    public let numberOfSimulators: UInt
    
    /** Tests execution strategy */
    public let scheduleStrategy: ScheduleStrategyType

    public init(
        numberOfSimulators: UInt,
        scheduleStrategy: ScheduleStrategyType)
    {
        self.numberOfSimulators = numberOfSimulators
        self.scheduleStrategy = scheduleStrategy
    }
}
