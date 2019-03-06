import Foundation

final class TestEventPairsController {
    private var testPairs = [FbXcTestEventPair]()
    private let workingQueue = DispatchQueue(label: "ru.avito.runner.TestEventPairsController.workingQueue")
    
    func append(_ pair: FbXcTestEventPair) {
        workingQueue.sync {
            testPairs.append(pair)
        }
    }
    
    var allPairs: [FbXcTestEventPair] {
        var results: [FbXcTestEventPair]?
        workingQueue.sync {
            results = testPairs
        }
        if let results = results {
            return results
        } else {
            return []
        }
    }
    
    var lastPair: FbXcTestEventPair? {
        var result: FbXcTestEventPair?
        workingQueue.sync {
            result = testPairs.last
        }
        return result
    }
    
    func popLast() -> FbXcTestEventPair? {
        var result: FbXcTestEventPair?
        workingQueue.sync {
            result = testPairs.popLast()
        }
        return result
    }
}
