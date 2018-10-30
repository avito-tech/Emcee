import Foundation
import Models

public final class RunResult {
    private var results = [TestEntry: [TestRunResult]]()
    
    public init() {}
    
    public func append(testEntryResult: TestEntryResult) {
        if let result = results[testEntryResult.testEntry] {
            results[testEntryResult.testEntry] = result + testEntryResult.testRunResults
        } else {
            results[testEntryResult.testEntry] = testEntryResult.testRunResults
        }
    }
    
    public func append(testEntryResults: [TestEntryResult]) {
        testEntryResults.forEach { append(testEntryResult: $0) }
    }
    
    public var testEntryResults: [TestEntryResult] {
        return results.map { (key: TestEntry, value: [TestRunResult]) -> TestEntryResult in
            if value.isEmpty {
                return .lost(testEntry: key)
            } else {
                return .withResults(testEntry: key, testRunResults: value)
            }
        }
    }
    
    public var nonLostTestEntryResults: [TestEntryResult] {
        return testEntryResults.filter { !$0.isLost }
    }
}
