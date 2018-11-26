import Foundation

public struct WorkerConfiguration: Codable, Equatable {
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** An interval the workers should use to report their aliveness to the queue server. */
    public let reportAliveInterval: TimeInterval

    public init(
        testRunExecutionBehavior: TestRunExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        reportAliveInterval: TimeInterval)
    {
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.reportAliveInterval = reportAliveInterval
    }
}
