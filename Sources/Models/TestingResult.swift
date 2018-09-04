import Foundation

/**
 * Represents the result of running a single Bucket.
 */
public struct TestingResult: Codable {
    /** A test bucket for this testing result. */
    public let bucket: Bucket

    /** All tests that succeded, after but excluding all possible attempts to restart the failed tests. */
    public let successfulTests: [TestRunResult]
    
    /** All tests that failed, excluding any attempts to restart them. */
    public let failedTests: [TestRunResult]
    
    /** All test results, including all restarts. A single test might be present multiple times. */
    public let unfilteredTestRuns: [TestRunResult]

    public init(
        bucket: Bucket,
        successfulTests: [TestRunResult],
        failedTests: [TestRunResult],
        unfilteredTestRuns: [TestRunResult])
    {
        self.bucket = bucket
        self.successfulTests = successfulTests
        self.failedTests = failedTests
        self.unfilteredTestRuns = unfilteredTestRuns
    }
    
    public static func emptyResult(bucket: Bucket) -> TestingResult {
        return TestingResult(bucket: bucket, successfulTests: [], failedTests: [], unfilteredTestRuns: [])
    }
}
