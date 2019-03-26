import Foundation

public extension OperationQueue {
    static func avito_with(maxConcurrentOperationCount: Int) -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = maxConcurrentOperationCount
        return queue
    }
}
