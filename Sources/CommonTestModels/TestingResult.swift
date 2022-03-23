import Foundation
import TestDestination

/// Represents the result of running a single Bucket.
public struct TestingResult: Codable, Hashable {
    
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
    
    public let xcresultData: [Data]

    public init(
        testDestination: TestDestination,
        unfilteredResults: [TestEntryResult],
        xcresultData: [Data]
    ) {
        self.testDestination = testDestination
        self.unfilteredResults = unfilteredResults
        self.xcresultData = xcresultData
    }
}

public enum MergeError: Error, CustomStringConvertible {
    case nothingToMerge
    case multipleBucketsFound([TestingResult], [TestDestination])
    
    public var description: String {
        switch self {
        case .nothingToMerge:
            return "Merge method has been called with empty array. At least a single \(type(of: TestingResult.self)) object must be provided."
        case .multipleBucketsFound(let results, let testDestinations):
            return "Failed to combine results (\(results)) as they have different test destinations: \(testDestinations)"
        }
    }
}

public extension TestingResult {
    
    static func byMerging(testingResults: [TestingResult]) throws -> TestingResult {
        guard testingResults.count > 0 else { throw MergeError.nothingToMerge }
        let testDestinations = Set(testingResults.map { $0.testDestination })
        guard testDestinations.count == 1, let testDestination = testDestinations.first else {
            throw MergeError.multipleBucketsFound(testingResults, Array(testDestinations))
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
            testDestination: testDestination,
            unfilteredResults: mergedResults,
            xcresultData: testingResults.flatMap(\.xcresultData)
        )
    }
}
