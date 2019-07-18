import Foundation

public struct TestTimeoutConfiguration: Codable, Equatable {
    /** A maximum duration for a single test. */
    public let singleTestMaximumDuration: TimeInterval
    
    /** A maximum allowed duration for a test runner stdout/stderr to be silent. */
    public let testRunnerMaximumSilenceDuration: TimeInterval

    public init(
        singleTestMaximumDuration: TimeInterval,
        testRunnerMaximumSilenceDuration: TimeInterval
    ) {
        self.singleTestMaximumDuration = singleTestMaximumDuration
        self.testRunnerMaximumSilenceDuration = testRunnerMaximumSilenceDuration
    }
}
