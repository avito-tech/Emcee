import Foundation

public struct TestEntryResult: Codable, CustomStringConvertible, Hashable {
    public let testEntry: TestEntry
    public let testRunResults: [TestRunResult]
    
    private init(testEntry: TestEntry, testRunResults: [TestRunResult]) {
        self.testEntry = testEntry
        self.testRunResults = testRunResults
    }
    
    public static func withResults(testEntry: TestEntry, testRunResults: [TestRunResult]) -> TestEntryResult {
        precondition(testRunResults.count > 0, "TestEntryResult '\(testEntry)' must have at least a single result!")
        return TestEntryResult(testEntry: testEntry, testRunResults: testRunResults)
    }
    
    public static func withResult(testEntry: TestEntry, testRunResult: TestRunResult) -> TestEntryResult {
        return TestEntryResult(testEntry: testEntry, testRunResults: [testRunResult])
    }
    
    public static func lost(testEntry: TestEntry) -> TestEntryResult {
        return TestEntryResult(testEntry: testEntry, testRunResults: [])
    }
    
    /// Indicates if runner was not able to start or finish the run of the test
    public var isLost: Bool {
        return testRunResults.isEmpty
    }
    
    public var succeeded: Bool {
        return !testRunResults.filter { $0.succeeded == true }.isEmpty
    }

    public var description: String {
        return "<\(type(of: self)) \(testEntry): \(succeeded ? "succeeded" : "failed"), \(testRunResults.count) runs: \(testRunResults)>"
    }
}
