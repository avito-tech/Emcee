import Foundation
import Models

public final class TestingResultFixtures {
    public let unfilteredResults: [TestEntryResult]    
    public let testEntry: TestEntry
    
    private let manuallyTestDestination: TestDestination?
    private let bucketId: BucketId
    
    public var testDestination: TestDestination {
        if let manuallyTestDestination = manuallyTestDestination {
            return manuallyTestDestination
        } else {
            return TestDestinationFixtures.testDestination
        }
    }
    
    public convenience init() {
        self.init(
            bucketId: UUID().uuidString,
            testEntry: TestEntryFixtures.testEntry(),
            manuallyTestDestination: nil,
            unfilteredResults: []
        )
    }
    
    public init(
        bucketId: BucketId,
        testEntry: TestEntry,
        manuallyTestDestination: TestDestination?,
        unfilteredResults: [TestEntryResult])
    {
        self.bucketId = bucketId
        self.testEntry = testEntry
        self.manuallyTestDestination = manuallyTestDestination
        self.unfilteredResults = unfilteredResults
    }
    
    public func testingResult() -> TestingResult {
        return TestingResult(
            bucketId: bucketId,
            testDestination: testDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func with(testEntry: TestEntry) -> TestingResultFixtures {
        return TestingResultFixtures(
            bucketId: bucketId,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func with(bucketId: BucketId) -> TestingResultFixtures {
        return TestingResultFixtures(
            bucketId: bucketId,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func addingLostResult() -> TestingResultFixtures {
        return TestingResultFixtures(
            bucketId: bucketId,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults + [TestEntryResult.lost(testEntry: testEntry)]
        )
    }
    
    public func addingResult(success: Bool) -> TestingResultFixtures {
        let result = TestEntryResult.withResult(
            testEntry: testEntry,
            testRunResult: TestRunResultFixtures.testRunResult(succeeded: success)
        )
        
        return TestingResultFixtures(
            bucketId: bucketId,
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults + [result]
        )
    }
}
