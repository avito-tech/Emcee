import Foundation

/// A per-test configuration that extends the global TestRunExecutionBehavior
public struct TestExecutionBehavior: Codable, Hashable {

    /// How many times each failed test should be attempted to restart
    public let numberOfRetries: UInt

    public init(numberOfRetries: UInt) {
        self.numberOfRetries = numberOfRetries
    }
}
