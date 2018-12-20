import Foundation

/// A per-test configuration that extends the global TestRunExecutionBehavior
public struct TestExecutionBehavior: Codable, Hashable {

    /// Test environment
    public let environment: [String: String]
    
    /// How many times each failed test should be attempted to restart
    public let numberOfRetries: UInt

    public init(
        environment: [String: String],
        numberOfRetries: UInt)
    {
        self.environment = environment
        self.numberOfRetries = numberOfRetries
    }
}
