import Foundation

/** A combination of TestingResult of all Buckets */
public struct CombinedTestingResults {
    
    /** All tests that succeded, after but excluding all possible attempts to restart the failed tests. */
    public let successfulTests: [TestRunResult]
    
    /** All tests that failed, excluding any attempts to restart them. */
    public let failedTests: [TestRunResult]
    
    /** All test results, including all restarts. A single test might be present multiple times. */
    public let unfilteredTestRuns: [TestRunResult]
    
    public init(testingResults: [TestingResult]) {
        self.successfulTests = testingResults.flatMap { $0.successfulTests }
        self.failedTests = testingResults.flatMap { $0.failedTests }
        self.unfilteredTestRuns = testingResults.flatMap { $0.unfilteredTestRuns }
    }
}
