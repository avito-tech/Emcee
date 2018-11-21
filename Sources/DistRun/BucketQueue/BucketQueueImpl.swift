import Dispatch
import Foundation
import Logging
import Models
import WorkerAlivenessTracker

final class BucketQueueImpl: BucketQueue {
    private var enqueuedBuckets = [Bucket]()
    private var dequeuedBuckets = Set<DequeuedBucket>()
    private let queue = DispatchQueue(label: "ru.avito.emcee.BucketQueue.queue")
    private let workerAlivenessTracker: WorkerAlivenessTracker
    private let workerRegistrar: WorkerRegistrar
    
    public init(workerAlivenessTracker: WorkerAlivenessTracker, workerRegistrar: WorkerRegistrar) {
        self.workerAlivenessTracker = workerAlivenessTracker
        self.workerRegistrar = workerRegistrar
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
        if !workerRegistrar.isWorkerRegistered(workerId: workerId) {
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
            throw BucketResultRequestError.noDequeuedBucket(requestId: requestId, workerId: workerId)
        }
        let requestTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(dequeuedBucket.bucket.testEntries)
        guard requestTestEntries == expectedTestEntries else {
            log("Validation failed: unexpected result count for request \(requestId) worker \(workerId)")
            blockWorker(workerId: workerId)
            throw BucketResultRequestError.notAllResultsAvailable(
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
                let workerIsBlocked = workerRegistrar.isWorkerBlocked(workerId: dequeuedBucket.workerId)
                let workerIsSilent = workerAlivenessTracker.alivenessForWorker(workerId: dequeuedBucket.workerId) == .silent
                let bucketIsStuck = workerIsBlocked || workerIsSilent
                
                if bucketIsStuck {
                    dequeuedBuckets.remove(dequeuedBucket)
                    if workerIsBlocked {
                        return StuckBucket(reason: .workerIsBlocked, bucket: dequeuedBucket.bucket, workerId: dequeuedBucket.workerId)
                    }
                    if workerIsSilent {
                        return StuckBucket(reason: .workerIsSilent, bucket: dequeuedBucket.bucket, workerId: dequeuedBucket.workerId)
                    }
                }
                return nil
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
    
    private func blockWorker(workerId: String) {
        log("WARNING: Blocking worker id from executing buckets: \(workerId)", color: .yellow)
        workerRegistrar.blockWorker(workerId: workerId)
        workerAlivenessTracker.didBlockWorker(workerId: workerId)
    }
    
    private func previouslyDequeuedBucket(requestId: String, workerId: String) -> DequeuedBucket? {
        return queue.sync {
            dequeuedBuckets.first { $0.requestId == requestId && $0.workerId == workerId }
        }
    }
}
