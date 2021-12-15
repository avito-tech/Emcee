import Foundation

/// A per-test configuration that extends the global TestRunExecutionBehavior
public struct TestExecutionBehavior: Codable, Hashable, CustomStringConvertible {

    /// Test environment
    public let environment: [String: String]
    
    /// Paths that will be appended to DYLD_INSERT_LIBRARIES environment variable
    public let userInsertedLibraries: [String]
    
    /// How many times each failed test should be attempted to restart
    public let numberOfRetries: UInt
    
    /// Defines where test reties occur.
    public let testRetryMode: TestRetryMode
    
    public func numberOfRetriesOnWorker() -> UInt {
        switch testRetryMode {
        case .retryOnWorker:
            return numberOfRetries
        case .retryThroughQueue:
            return 0
        }
    }

    public init(
        environment: [String: String],
        userInsertedLibraries: [String],
        numberOfRetries: UInt,
        testRetryMode: TestRetryMode
    )
    {
        self.environment = environment
        self.userInsertedLibraries = userInsertedLibraries
        self.numberOfRetries = numberOfRetries
        self.testRetryMode = testRetryMode
    }
    
    public var description: String {
        return "numberOfRetries: \(numberOfRetries), testRetryMode: \(testRetryMode), environment: \(environment), userInsertedLibraries: \(userInsertedLibraries)"
    }
}
