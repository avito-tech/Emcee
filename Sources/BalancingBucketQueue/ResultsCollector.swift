import Extensions
import Foundation
import QueueModels

public final class ResultsCollector {
    private let lock = NSLock()
    private var testingResults = [TestingResult]()
    
    public init() {}
    
    public func append(testingResult: TestingResult) {
        lock.whileLocked {
            testingResults.append(testingResult)
        }
    }
    
    public var collectedResults: [TestingResult] {
        lock.whileLocked { testingResults }
    }
}
