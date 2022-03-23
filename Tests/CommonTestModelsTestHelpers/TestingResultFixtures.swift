import CommonTestModels
import Foundation
import QueueModels
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestDestination

public final class TestingResultFixtures {
    public let unfilteredResults: [TestEntryResult]    
    public let testEntry: TestEntry
    
    public var manuallyTestDestination: TestDestination?
    
    public var testDestination: TestDestination {
        if let manuallyTestDestination = manuallyTestDestination {
            return manuallyTestDestination
        } else {
            return TestDestination()
        }
    }

    public init(
        testEntry: TestEntry = TestEntryFixtures.testEntry(),
        manuallyTestDestination: TestDestination? = nil,
        unfilteredResults: [TestEntryResult] = []
    ) {
        self.testEntry = testEntry
        self.manuallyTestDestination = manuallyTestDestination
        self.unfilteredResults = unfilteredResults
    }
    
    public func testingResult() -> TestingResult {
        return TestingResult(
            testDestination: testDestination,
            unfilteredResults: unfilteredResults,
            xcresultData: []
        )
    }
    
    public func with(testEntry: TestEntry) -> TestingResultFixtures {
        return TestingResultFixtures(
            testEntry: testEntry,
            manuallyTestDestination: manuallyTestDestination,
            unfilteredResults: unfilteredResults
        )
    }
    
    public func with(manuallyTestDestination: TestDestination?) -> TestingResultFixtures {
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
