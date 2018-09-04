import Foundation

public struct WorkerConfiguration: Codable {
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    
    /** An interval the workers should use to report their aliveness to the queue server. */
    public let reportAliveInterval: TimeInterval

    public init(
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        reportAliveInterval: TimeInterval = 30.0)
    {
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.reportAliveInterval = reportAliveInterval
    }
}
