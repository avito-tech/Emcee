import Foundation
import Models
import XCTest

final class TestingResultTests: XCTestCase {
    func testFilteringResults() throws {
        let result = TestingResult(
            bucketId: "id",
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            unfilteredResults: [
                .withResult(
                    testEntry: TestEntry(className: "success", methodName: "", caseId: nil),
                    testRunResult: testRunResult(succeeded: true, ts: 0)),
                .withResult(
                    testEntry: TestEntry(className: "failure", methodName: "", caseId: nil),
                    testRunResult: testRunResult(succeeded: false, ts: 0))
            ])
        
        XCTAssertEqual(result.successfulTests.count, 1)
        XCTAssertEqual(result.successfulTests[0].testEntry.className, "success")
        
        XCTAssertEqual(result.failedTests.count, 1)
        XCTAssertEqual(result.failedTests[0].testEntry.className, "failure")
        
        XCTAssertEqual(result.unfilteredResults.count, 2)
    }
    
    func testFilteringResultsWithMultipleRuns() throws {
        let result = TestingResult(
            bucketId: "id",
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            unfilteredResults: [
                .withResults(
                    testEntry: TestEntry(className: "success", methodName: "", caseId: nil),
                    testRunResults: [
                        testRunResult(succeeded: true, ts: 0),
                        testRunResult(succeeded: false, ts: 2)
                    ])
            ])
        
        XCTAssertEqual(result.successfulTests.count, 1)
        XCTAssertEqual(result.successfulTests[0].testEntry.className, "success")
        
        XCTAssertEqual(result.failedTests.count, 0)
    }
    
    func testMerging() throws {
        let testDestination = try TestDestination(deviceType: "device", iOSVersion: "11.3")
        let testEntry1 = TestEntry(className: "success", methodName: "", caseId: nil)
        let testEntry2 = TestEntry(className: "failure", methodName: "", caseId: nil)
        
        let result1 = TestingResult(
            bucketId: "id",
            testDestination: testDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry1,
                    testRunResults: [
                        testRunResult(succeeded: true, ts: 10),
                        testRunResult(succeeded: false, ts: 11)
                    ])
            ])
        let result2 = TestingResult(
            bucketId: "id",
            testDestination: testDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry1,
                    testRunResults: [
                        testRunResult(succeeded: false, ts: 0),
                        testRunResult(succeeded: false, ts: 1)
                    ])
            ])
        let result3 = TestingResult(
            bucketId: "id",
            testDestination: testDestination,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry2,
                    testRunResults: [
                        testRunResult(succeeded: false, ts: 42)
                    ])
            ])
        
        let merged = try TestingResult.byMerging(testingResults: [result1, result2, result3])
        
        XCTAssertEqual(merged.bucketId, "id")
        XCTAssertEqual(merged.unfilteredResults.count, 2)
        
        XCTAssertEqual(merged.successfulTests.count, 1)
        XCTAssertEqual(merged.successfulTests[0].testEntry, testEntry1)
        XCTAssertEqual(merged.successfulTests[0].testRunResults.count, 4)
        
        XCTAssertEqual(merged.failedTests.count, 1)
        XCTAssertEqual(merged.failedTests[0].testEntry, testEntry2)
        XCTAssertEqual(merged.failedTests[0].testRunResults.count, 1)
        XCTAssertEqual(merged.failedTests[0].testRunResults[0].startTime, 42, accuracy: 0.1)
    }
    
    func testMergingMismatchingBucketsFails() throws {
        let testDestination1 = try TestDestination(deviceType: "device", iOSVersion: "11.3")
        let testDestination2 = try TestDestination(deviceType: "device", iOSVersion: "10.0")
        let testEntry = TestEntry(className: "success", methodName: "", caseId: nil)
        
        let result1 = TestingResult(
            bucketId: "id1",
            testDestination: testDestination1,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry,
                    testRunResults: [
                        testRunResult(succeeded: true, ts: 10),
                        testRunResult(succeeded: false, ts: 11)
                    ])
            ])
        let result2 = TestingResult(
            bucketId: "id2",
            testDestination: testDestination2,
            unfilteredResults: [
                .withResults(
                    testEntry: testEntry,
                    testRunResults: [
                        testRunResult(succeeded: false, ts: 0),
                        testRunResult(succeeded: false, ts: 1)
                    ])
            ])
        XCTAssertThrowsError(_ = try TestingResult.byMerging(testingResults: [result1, result2]))
    }
    
    func testTreatingLostResultAsFailure() throws {
        let result = TestingResult(
            bucketId: "id",
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "11.3"),
            unfilteredResults: [
                .lost(testEntry: TestEntry(className: "lost", methodName: "", caseId: nil))
            ])
        
        XCTAssertEqual(result.successfulTests.count, 0)
        
        XCTAssertEqual(result.failedTests.count, 1)
        XCTAssertEqual(result.failedTests[0].testEntry.className, "lost")
        
        XCTAssertEqual(result.unfilteredResults.count, 1)
    }
    
    private func testRunResult(succeeded: Bool, ts: TimeInterval) -> TestRunResult {
        return TestRunResult(
            succeeded: succeeded,
            exceptions: [],
            duration: 0,
            startTime: ts,
            finishTime: ts,
            hostName: "",
            processId: 0,
            simulatorId: "")
    }
}

