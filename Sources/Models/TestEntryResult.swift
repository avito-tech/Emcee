import Foundation

public struct TestEntryResult: Codable, CustomStringConvertible {
    public let testEntry: TestEntry
    public let testRunResults: [TestRunResult]
    
    public init(testEntry: TestEntry, testRunResults: [TestRunResult]) {
        precondition(testRunResults.count > 0, "TestEntryResult '\(testEntry)' must have at least a single result!")
        self.testEntry = testEntry
        self.testRunResults = testRunResults
    }
    
    public init(testEntry: TestEntry, testRunResult: TestRunResult) {
        self.init(testEntry: testEntry, testRunResults: [testRunResult])
    }
    
    public var succeeded: Bool {
        return !testRunResults.filter { $0.succeeded == true }.isEmpty
    }

    public var description: String {
        return "<\(type(of: self)) \(testEntry): \(succeeded ? "succeeded" : "failed"), \(testRunResults.count) runs>"
    }
}
