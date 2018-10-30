import Foundation

/// Represents the result of running a single Bucket.
public struct TestingResult: Codable {
    /// A test bucket for this testing result.
    public let bucket: Bucket
    
    /// All test results
    public let unfilteredResults: [TestEntryResult]

    /// All tests that succeded
    public var successfulTests: [TestEntryResult] {
        return unfilteredResults.filter { $0.succeeded == true }
    }
    
    /// All tests that failed
    public var failedTests: [TestEntryResult] {
        return unfilteredResults.filter { $0.succeeded == false }
    }

    public init(
        bucket: Bucket,
        unfilteredResults: [TestEntryResult])
    {
        self.bucket = bucket
        self.unfilteredResults = unfilteredResults
    }
}

public enum MergeError: Error, CustomStringConvertible {
    case nothingToMerge
    case multipleBucketsFound([TestingResult], [Bucket])
    
    public var description: String {
        switch self {
        case .nothingToMerge:
            return "Merge method has been called with empty array. At least a single \(type(of: TestingResult.self)) object must be provided."
        case .multipleBucketsFound(let results, let buckets):
            return "Failed to combine results (\(results)) as they have different buckets (\(buckets))"
        }
    }
}

public extension TestingResult {
    
    public static func byMerging(testingResults: [TestingResult]) throws -> TestingResult {
        guard testingResults.count > 0 else { throw MergeError.nothingToMerge }
        let buckets = Set(testingResults.map { $0.bucket })
        guard buckets.count == 1, let bucket = buckets.first else { throw MergeError.multipleBucketsFound(testingResults, Array(buckets)) }
        
        var testEntryResults = [TestEntry: [TestRunResult]]()
        
        for testingResult in testingResults {
            for testEntryResult in testingResult.unfilteredResults {
                if let result = testEntryResults[testEntryResult.testEntry] {
                    testEntryResults[testEntryResult.testEntry] = testEntryResult.testRunResults + result
                } else {
                    testEntryResults[testEntryResult.testEntry] = testEntryResult.testRunResults
                }
            }
        }
        let mergedResults = testEntryResults.map { (testEntry: TestEntry, runResults: [TestRunResult]) -> TestEntryResult in
            .withResults(testEntry: testEntry, testRunResults: runResults)
        }
        return TestingResult(bucket: bucket, unfilteredResults: mergedResults)
    }
}
