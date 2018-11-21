import Dispatch
import Foundation
import Logging
import Models
import WorkerAlivenessTracker

final class BucketQueueImpl: BucketQueue {
    private var enqueuedBuckets = [Bucket]()
    private var dequeuedBuckets = Set<DequeuedBucket>()
    private let queue = DispatchQueue(label: "ru.avito.emcee.BucketQueue.queue")
    private let workerAlivenessProvider: WorkerAlivenessProvider
    
    public init(workerAlivenessProvider: WorkerAlivenessProvider) {
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func enqueue(buckets: [Bucket]) {
        queue.sync {
            self.enqueuedBuckets.append(contentsOf: buckets)
        }
    }
    
    public var state: BucketQueueState {
        return queue.sync {
            BucketQueueState(enqueuedBucketCount: enqueuedBuckets.count, dequeuedBucketCount: dequeuedBuckets.count)
        }
    }
    
    public func dequeueBucket(requestId: String, workerId: String) -> DequeueResult {
        if workerAlivenessProvider.alivenessForWorker(workerId: workerId) != .alive {
            return .workerBlocked
        }
        
        if let previouslyDequeuedBucket = previouslyDequeuedBucket(requestId: requestId, workerId: workerId) {
            log("Provided previously dequeued bucket: \(previouslyDequeuedBucket)")
            return .dequeuedBucket(previouslyDequeuedBucket)
        }
        
        let state = self.state
        if state.isDepleted { return .queueIsEmpty }
        if state.enqueuedBucketCount == 0 { return .queueIsEmptyButNotAllResultsAreAvailable }
        
        let bucket = pickBucket()
        let dequeuedBucket = DequeuedBucket(bucket: bucket, workerId: workerId, requestId: requestId)
        didDequeue(dequeuedBucket: dequeuedBucket)
        return .dequeuedBucket(dequeuedBucket)
    }
    
    public func accept(testingResult: TestingResult, requestId: String, workerId: String) throws {
        log("Validating result from \(workerId): \(testingResult)")
        
        guard let dequeuedBucket = previouslyDequeuedBucket(requestId: requestId, workerId: workerId) else {
            log("Validation failed: no dequeued bucket for request \(requestId) worker \(workerId)")
            throw ResultAcceptanceError.noDequeuedBucket(requestId: requestId, workerId: workerId)
        }
        let requestTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(dequeuedBucket.bucket.testEntries)
        guard requestTestEntries == expectedTestEntries else {
            log("Validation failed: unexpected result count for request \(requestId) worker \(workerId)")
            throw ResultAcceptanceError.notAllResultsAvailable(
                requestId: requestId,
                workerId: workerId,
                expectedTestEntries: dequeuedBucket.bucket.testEntries,
                providedResults: testingResult.unfilteredResults)
        }
        
        queue.sync {
            dequeuedBuckets.remove(dequeuedBucket)
            log("Accepted result for bucket '\(testingResult.bucketId)' from '\(workerId)', updated dequeued buckets: \(dequeuedBuckets.count): \(dequeuedBuckets)")
        }
    }
    
    /// Removes and returns any buckets that appear to be stuck, providing a reason why queue thinks bucket is stuck.
    public func removeStuckBuckets() -> [StuckBucket] {
        return queue.sync {
            let allDequeuedBuckets = dequeuedBuckets
            let stuckBuckets: [StuckBucket] = allDequeuedBuckets.compactMap { dequeuedBucket in
                let aliveness = workerAlivenessProvider.alivenessForWorker(workerId: dequeuedBucket.workerId)
                switch aliveness {
                case .alive:
                    return nil
                case .notRegistered:
                    fatalLogAndError("Logic error: worker '\(dequeuedBucket.workerId)' is not registered, but stuck bucket has worker id of this worker. This is not expected, as we shouldn't dequeue bucket using non-registered worker.")
                case .blocked:
                    dequeuedBuckets.remove(dequeuedBucket)
                    return StuckBucket(reason: .workerIsBlocked, bucket: dequeuedBucket.bucket, workerId: dequeuedBucket.workerId)
                case .silent:
                    dequeuedBuckets.remove(dequeuedBucket)
                    return StuckBucket(reason: .workerIsSilent, bucket: dequeuedBucket.bucket, workerId: dequeuedBucket.workerId)
                }
            }
            return stuckBuckets
        }
    }
    
    private func didDequeue(dequeuedBucket: DequeuedBucket) {
        queue.sync {
            _ = dequeuedBuckets.insert(dequeuedBucket)
            log("Dequeued new bucket: \(dequeuedBucket). Now there are \(dequeuedBuckets.count) dequeued buckets.")
        }
    }
    
    private func pickBucket() -> Bucket {
        return queue.sync {
            enqueuedBuckets.removeFirst()
        }
    }
    
    private func previouslyDequeuedBucket(requestId: String, workerId: String) -> DequeuedBucket? {
        return queue.sync {
            dequeuedBuckets.first { $0.requestId == requestId && $0.workerId == workerId }
        }
    }
}
