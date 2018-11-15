import Foundation
import Models

public final class ResultsCollector {
    private let queue = DispatchQueue(label: "ru.avito.emcee.ResultsCollector.queue")
    private var testingResults = [TestingResult]()
    
    public init() {}
    
    public func append(testingResult: TestingResult) {
        queue.sync { testingResults.append(testingResult) }
    }
    
    public var collectedResults: [TestingResult] {
        return queue.sync { testingResults }
    }
}
