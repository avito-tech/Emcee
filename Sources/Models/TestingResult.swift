import Foundation

/// Represents the result of running a single Bucket.
public struct TestingResult: Codable, Equatable {
    /// A test bucket id for this testing result.
    public let bucketId: BucketId
    
    /// A test destination used to run the tests.
    public let testDestination: TestDestination
    
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
        bucketId: BucketId,
        testDestination: TestDestination,
        unfilteredResults: [TestEntryResult])
    {
        self.bucketId = bucketId
        self.testDestination = testDestination
        self.unfilteredResults = unfilteredResults
    }
}

public enum MergeError: Error, CustomStringConvertible {
    case nothingToMerge
    case multipleBucketsFound([TestingResult], [BucketId])
    
    public var description: String {
        switch self {
        case .nothingToMerge:
            return "Merge method has been called with empty array. At least a single \(type(of: TestingResult.self)) object must be provided."
        case .multipleBucketsFound(let results, let bucketIds):
            return "Failed to combine results (\(results)) as they have different bucket ids: (\(bucketIds))"
        }
    }
}

public extension TestingResult {
    
    static func byMerging(testingResults: [TestingResult]) throws -> TestingResult {
        guard testingResults.count > 0 else { throw MergeError.nothingToMerge }
        let bucketIds = Set(testingResults.map { $0.bucketId })
        let testDestinations = Set(testingResults.map { $0.testDestination })
        guard bucketIds.count == 1,
            let bucketId = bucketIds.first,
            let testDestination = testDestinations.first else
        {
            throw MergeError.multipleBucketsFound(testingResults, Array(bucketIds))
        }
        
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
        return TestingResult(
            bucketId: bucketId,
            testDestination: testDestination,
            unfilteredResults: mergedResults)
    }
}
