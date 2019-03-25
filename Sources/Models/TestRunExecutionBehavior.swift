import Foundation

/** Defines the specifics of the behavior of the test run. */
public struct TestRunExecutionBehavior: Codable, Equatable {
    
    /** A maximum number of attempts to re-run failed tests. */
    public let numberOfRetries: UInt
    
    /** Maximum number of simulators to create and use in parallel. */
    public let numberOfSimulators: UInt
    
    /** Tests execution strategy */
    public let scheduleStrategy: ScheduleStrategyType

    public init(
        numberOfRetries: UInt,
        numberOfSimulators: UInt,
        scheduleStrategy: ScheduleStrategyType)
    {
        self.numberOfRetries = numberOfRetries
        self.numberOfSimulators = numberOfSimulators
        self.scheduleStrategy = scheduleStrategy
    }
}
