import Foundation

public struct TestEventPair {
    public let startEvent: TestStartedEvent
    public let finishEvent: TestFinishedEvent?

    public init(startEvent: TestStartedEvent, finishEvent: TestFinishedEvent?) {
        self.startEvent = startEvent
        self.finishEvent = finishEvent
    }
}

final class TestEventPairsController {
    private var testPairs = [TestEventPair]()
    private let workingQueue = DispatchQueue(label: "ru.avito.runner.TestEventPairsController.workingQueue")
    
    func append(_ pair: TestEventPair) {
        workingQueue.sync {
            testPairs.append(pair)
        }
    }
    
    var allPairs: [TestEventPair] {
        var results: [TestEventPair]?
        workingQueue.sync {
            results = testPairs
        }
        if let results = results {
            return results
        } else {
            return []
        }
    }
    
    var lastPair: TestEventPair? {
        var result: TestEventPair?
        workingQueue.sync {
            result = testPairs.last
        }
        return result
    }
    
    func popLast() -> TestEventPair? {
        var result: TestEventPair?
        workingQueue.sync {
            result = testPairs.popLast()
        }
        return result
    }
}
