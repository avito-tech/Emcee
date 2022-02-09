import Foundation
import QueueModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestDestination
import XCTest

final class TestingResultTests: XCTestCase {
    func testFilteringResults() throws {
        let result = TestingResult(
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            unfilteredResults: [
                .withResult(
                    testEntry: TestEntryFixtures.testEntry(className: "success", methodName: ""),
                    testRunResult: TestRunResultFixtures.testRunResult(succeeded: true, timestamp: 0)),
                .withResult(
                    testEntry: TestEntryFixtures.testEntry(className: "failure", methodName: ""),
                    testRunResult: TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 0))
            ])
        
        XCTAssertEqual(result.successfulTests.count, 1)
        XCTAssertEqual(result.successfulTests[0].testEntry.testName.className, "success")
        
        XCTAssertEqual(result.failedTests.count, 1)
        XCTAssertEqual(result.failedTests[0].testEntry.testName.className, "failure")
        
        XCTAssertEqual(result.unfilteredResults.count, 2)
    }
    
    func testFilteringResultsWithMultipleRuns() throws {
        let result = TestingResult(
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: TestEntryFixtures.testEntry(className: "success", methodName: ""),
                    testRunResults: [
                        TestRunResultFixtures.testRunResult(succeeded: true, timestamp: 0),
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 2)
                    ])
            ])
        
        XCTAssertEqual(result.successfulTests.count, 1)
        XCTAssertEqual(result.successfulTests[0].testEntry.testName.className, "success")
        
        XCTAssertEqual(result.failedTests.count, 0)
    }
    
    func testMerging() throws {
        let testDestination = TestDestinationAppleFixtures.iOSTestDestination
        let testEntry1 = TestEntryFixtures.testEntry(className: "success", methodName: "")
        let testEntry2 = TestEntryFixtures.testEntry(className: "failure", methodName: "")
        
        let result1 = TestingResult(
            testDestination: testDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry1,
                    testRunResults: [
                        TestRunResultFixtures.testRunResult(succeeded: true, timestamp: 10),
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 11)
                    ])
            ])
        let result2 = TestingResult(
            testDestination: testDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry1,
                    testRunResults: [
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 0),
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 1)
                    ])
            ])
        let result3 = TestingResult(
            testDestination: testDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry2,
                    testRunResults: [
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 42)
                    ])
            ])
        
        let merged = try TestingResult.byMerging(testingResults: [result1, result2, result3])
        
        XCTAssertEqual(merged.unfilteredResults.count, 2)
        
        XCTAssertEqual(merged.successfulTests.count, 1)
        XCTAssertEqual(merged.successfulTests[0].testEntry, testEntry1)
        XCTAssertEqual(merged.successfulTests[0].testRunResults.count, 4)
        
        XCTAssertEqual(merged.failedTests.count, 1)
        XCTAssertEqual(merged.failedTests[0].testEntry, testEntry2)
        XCTAssertEqual(merged.failedTests[0].testRunResults.count, 1)
        XCTAssertEqual(merged.failedTests[0].testRunResults[0].startTime.timeIntervalSince1970, 42, accuracy: 0.1)
    }
    
    func testMergingMismatchingBucketsFails() {
        let testDestination1 = TestDestination.iOSSimulator(deviceType: "device", version: "11.3")
        let testDestination2 = TestDestination.iOSSimulator(deviceType: "device", version: "10.0")
        let testEntry = TestEntryFixtures.testEntry(className: "success", methodName: "")
        
        let result1 = TestingResult(
            testDestination: testDestination1,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry,
                    testRunResults: [
                        TestRunResultFixtures.testRunResult(succeeded: true, timestamp: 10),
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 11)
                    ])
            ])
        let result2 = TestingResult(
            testDestination: testDestination2,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry,
                    testRunResults: [
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 0),
                        TestRunResultFixtures.testRunResult(succeeded: false, timestamp: 1)
                    ])
            ])
        XCTAssertThrowsError(_ = try TestingResult.byMerging(testingResults: [result1, result2]))
    }
    
    func testTreatingLostResultAsFailure() {
        let result = TestingResult(
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            unfilteredResults: [
                .lost(testEntry: TestEntryFixtures.testEntry(className: "lost", methodName: ""))
            ])
        
        XCTAssertEqual(result.successfulTests.count, 0)
        
        XCTAssertEqual(result.failedTests.count, 1)
        XCTAssertEqual(result.failedTests[0].testEntry.testName.className, "lost")
        
        XCTAssertEqual(result.unfilteredResults.count, 1)
    }
}

