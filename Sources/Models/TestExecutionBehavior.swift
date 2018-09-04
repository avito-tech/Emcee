import Foundation

/** Defines the specifics of the behavior of the test run. */
public struct TestExecutionBehavior: Codable {
    
    /** A maximum number of attempts to re-run failed tests. */
    public let numberOfRetries: UInt
    
    /** Maximum number of simulators to create and use in parallel. */
    public let numberOfSimulators: UInt
    
    /** The enviroment variables under which tests should run. */
    public let environment: [String: String]
    
    /** Tests execution strategy */
    public let scheduleStrategy: ScheduleStrategyType

    public init(
        numberOfRetries: UInt,
        numberOfSimulators: UInt,
        environment: [String: String],
        scheduleStrategy: ScheduleStrategyType)
    {
        self.numberOfRetries = numberOfRetries
        self.numberOfSimulators = numberOfSimulators
        self.environment = environment
        self.scheduleStrategy = scheduleStrategy
    }
    
    public func withEnvironmentOverrides(_ overrides: [String: String]) -> TestExecutionBehavior {
        var environment = self.environment
        overrides.forEach { (key, value) in
            environment.updateValue(value, forKey: key)
        }
        return TestExecutionBehavior(
            numberOfRetries: numberOfRetries,
            numberOfSimulators: numberOfSimulators,
            environment: environment,
            scheduleStrategy: scheduleStrategy)
    }
}
