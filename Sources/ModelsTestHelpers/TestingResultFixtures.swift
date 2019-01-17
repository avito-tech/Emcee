import Foundation
import Models

public final class TestingResultFixtures {
    public let unfilteredResults: [TestEntryResult]    
    public let testEntry: TestEntry
    
    private let manuallyTestDestination: TestDestination?
    private let manuallySetBucket: Bucket?
    private let numberOfRetriesForBucket: UInt
    
    public var testDestination: TestDestination {
        if let manuallyTestDestination = manuallyTestDestination {
            return manuallyTestDestination
        } else if let manuallySetBucket = manuallySetBucket {
            return manuallySetBucket.testDestination
        } else {
            return TestDestinationFixtures.testDestination
        }
    }
    
    public var bucket: Bucket {
        if let manuallySetBucket = manuallySetBucket {
            return manuallySetBucket
        } else {
            let uniqueTestEntries = Array(Set(unfilteredResults.map { $0.testEntry }))
            return BucketFixtures.createBucket(
                testEntries: uniqueTestEntries,
                numberOfRetries: numberOfRetriesForBucket
            )
        }
    }
    
    public convenience init() {
        self.init(
            manuallySetBucket: nil,
            testEntry: TestEntryFixtures.testEntry(),
            manuallyTestDestination: nil,
            unfilteredResults: [],
            numberOfRetriesForBucket: 0
        )
    }
    
    public init(
        manuallySetBucket: Bucket?,
        testEntry: TestEntry,
        manuallyTestDestination: TestDestination?,
        unfilteredResults: [TestEntryResult],
        numberOfRetriesForBucket: UInt = 0)
    {
        self.manuallySetBucket = manuallySetBucket
        self.testEntry = testEntry
        self.manuallyTestDestination = manuallyTestDestination
        self.unfilteredResults = unfilteredResults
        self.numberOfRetriesForBucket = numberOfRetriesForBucket
    }
    
    public func testingResult() -> TestingResult {
        return TestingResult(
            bucketId: bucket.bucketId,
            testDestination: testDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func with(testEntry: TestEntry) -> TestingResultFixtures {
        return TestingResultFixtures(
            manuallySetBucket: manuallySetBucket,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults,
            numberOfRetriesForBucket: numberOfRetriesForBucket
        )
    }
    
    public func with(bucket: Bucket) -> TestingResultFixtures {
        return TestingResultFixtures(
            manuallySetBucket: bucket,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults,
            numberOfRetriesForBucket: numberOfRetriesForBucket
        )
    }
    
    public func with(numberOfRetiresOfBucket count: UInt) -> TestingResultFixtures {
        return TestingResultFixtures(
            manuallySetBucket: manuallySetBucket,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults,
            numberOfRetriesForBucket: count
        )
    }
    
    public func addingLostResult() -> TestingResultFixtures {
        return TestingResultFixtures(
            manuallySetBucket: manuallySetBucket,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults + [TestEntryResult.lost(testEntry: testEntry)],
            numberOfRetriesForBucket: numberOfRetriesForBucket
        )
    }
    
    public func addingResult(success: Bool) -> TestingResultFixtures {
        let result = TestEntryResult.withResult(
            testEntry: testEntry,
            testRunResult: TestRunResultFixtures.testRunResult(succeeded: success)
        )
        
        return TestingResultFixtures(
            manuallySetBucket: manuallySetBucket,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults + [result],
            numberOfRetriesForBucket: numberOfRetriesForBucket
        )
    }
}
