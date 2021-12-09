import EmceeExtensions
import Foundation
import QueueModels

public final class ResultsCollector {
    private let lock = NSLock()
    private var bucketResults = [BucketResult]()
    
    public init() {}
    
    public func append(bucketResult: BucketResult) {
        lock.whileLocked {
            bucketResults.append(bucketResult)
        }
    }
    
    public var collectedResults: [BucketResult] {
        lock.whileLocked { bucketResults }
    }
}
