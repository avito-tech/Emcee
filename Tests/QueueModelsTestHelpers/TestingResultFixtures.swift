import Foundation
import QueueModels
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers

public final class TestingResultFixtures {
    public let unfilteredResults: [TestEntryResult]    
    public let testEntry: TestEntry
    
    private let manuallyTestDestination: TestDestination?
    
    public var testDestination: TestDestination {
        if let manuallyTestDestination = manuallyTestDestination {
            return manuallyTestDestination
        } else {
            return TestDestinationFixtures.testDestination
        }
    }
    
    public convenience init() {
        self.init(
            testEntry: TestEntryFixtures.testEntry(),
            manuallyTestDestination: nil,
            unfilteredResults: []
        )
    }
    
    public init(
        testEntry: TestEntry,
        manuallyTestDestination: TestDestination?,
        unfilteredResults: [TestEntryResult])
    {
        self.testEntry = testEntry
        self.manuallyTestDestination = manuallyTestDestination
        self.unfilteredResults = unfilteredResults
    }
    
    public func testingResult() -> TestingResult {
        return TestingResult(
            testDestination: testDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func with(testEntry: TestEntry) -> TestingResultFixtures {
        return TestingResultFixtures(
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func addingLostResult() -> TestingResultFixtures {
        return TestingResultFixtures(
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
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults + [result]
        )
    }
}
