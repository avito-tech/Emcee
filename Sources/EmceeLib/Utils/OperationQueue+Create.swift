import Foundation

extension OperationQueue {
    static func create(
        name: String,
        maxConcurrentOperationCount: Int,
        qualityOfService: QualityOfService
    ) -> OperationQueue {
        let queue = OperationQueue()
        queue.name = name
        queue.maxConcurrentOperationCount = maxConcurrentOperationCount
        queue.qualityOfService = qualityOfService
        return queue
    }
}
