import Foundation
import QueueModels

public final class ResultsCollector {
    private let queue = DispatchQueue(label: "ResultsCollector.queue")
    private var testingResults = [TestingResult]()
    
    public init() {}
    
    public func append(testingResult: TestingResult) {
        queue.sync { testingResults.append(testingResult) }
    }
    
    public var collectedResults: [TestingResult] {
        return queue.sync { testingResults }
    }
}
