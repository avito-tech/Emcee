import DateProvider
import Dispatch
import Foundation
import Logging
import Models
import UniqueIdentifierGenerator
import WorkerAlivenessTracker

final class BucketQueueImpl: BucketQueue {
    private let dateProvider: DateProvider
    private var enqueuedBuckets = [EnqueuedBucket]()
    private var dequeuedBuckets = Set<DequeuedBucket>()
    private let testHistoryTracker: TestHistoryTracker
    private let queue = DispatchQueue(label: "ru.avito.emcee.BucketQueue.queue")
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let checkAgainTimeInterval: TimeInterval
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        testHistoryTracker: TestHistoryTracker,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessProvider: WorkerAlivenessProvider
        )
    {
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.dateProvider = dateProvider
        self.testHistoryTracker = testHistoryTracker
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func enqueue(buckets: [Bucket]) {
        queue.sync {
            self.enqueue_onSyncQueue(buckets: buckets)
        }
    }
    
    public var queueState: QueueState {
        return queue.sync {
            return state_onSyncQueue
        }
    }

    public var runningQueueState: RunningQueueState {
        return queue.sync {
            runningQueueState_onSyncQueue
        }
    }
    
    private var state_onSyncQueue: QueueState {
        return QueueState.running(runningQueueState_onSyncQueue)
    }

    private var runningQueueState_onSyncQueue: RunningQueueState {
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBuckets.count,
            dequeuedBucketCount: dequeuedBuckets.count
        )
    }
    
    func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return queue.sync {
            previouslyDequeuedBucket_onSyncQueue(requestId: requestId, workerId: workerId)
        }
    }
    
    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        switch workerAlivenessProvider.alivenessForWorker(workerId: workerId).status {
        case .blocked:
            return .workerIsBlocked
        case .silent, .notRegistered:
            return .workerIsNotAlive
        case .alive:
            break
        }

        return queue.sync {
            // There might me problems with connection between workers and queue and connection may be lost.
            // If same worker tries to perform same request again, return same result.
            if let previouslyDequeuedBucket = previouslyDequeuedBucket_onSyncQueue(requestId: requestId, workerId: workerId) {
                Logger.debug("Provided previously dequeued bucket: \(previouslyDequeuedBucket)")
                return .dequeuedBucket(previouslyDequeuedBucket)
            }
            
            if runningQueueState_onSyncQueue.isDepleted {
                return .queueIsEmpty
            }
            if runningQueueState_onSyncQueue.enqueuedBucketCount == 0 {
                return .checkAgainLater(checkAfter: checkAgainTimeInterval)
            }
            
            let bucketToDequeueOrNil = testHistoryTracker.bucketToDequeue(
                workerId: workerId,
                queue: enqueuedBuckets,
                aliveWorkers: workerAlivenessProvider.aliveWorkerIds
            )
            
            if let enqueuedBucket = bucketToDequeueOrNil {
                return .dequeuedBucket(
                    dequeue_onSyncQueue(
                        enqueuedBucket: enqueuedBucket,
                        requestId: requestId,
                        workerId: workerId
                    )
                )
            } else {
                return .checkAgainLater(checkAfter: checkAgainTimeInterval)
            }
        }
    }
    
    func removeAllEnqueuedBuckets() {
        queue.sync {
            Logger.debug("Removing all enqueued buckets (\(enqueuedBuckets.count) items)")
            enqueuedBuckets.removeAll()
        }
    }
    
    public func accept(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId
        ) throws -> BucketQueueAcceptResult
    {
        return try queue.sync {
            Logger.debug("Validating result from \(workerId) \(requestId): \(testingResult)")
            
            guard let dequeuedBucket = previouslyDequeuedBucket_onSyncQueue(requestId: requestId, workerId: workerId) else {
                Logger.error("No dequeued bucket for \(workerId)")
                Logger.verboseDebug("Validation failed: no dequeued bucket for \(requestId) \(workerId)")
                throw ResultAcceptanceError.noDequeuedBucket(requestId: requestId, workerId: workerId)
            }
            
            let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
            let expectedTestEntries = Set(dequeuedBucket.enqueuedBucket.bucket.testEntries)
            try reenqueueLostResults_onSyncQueue(
                expectedTestEntries: expectedTestEntries,
                actualTestEntries: actualTestEntries,
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: workerId,
                requestId: requestId
            )
            
            let acceptResult = try testHistoryTracker.accept(
                testingResult: testingResult,
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: workerId
            )
            enqueue_onSyncQueue(buckets: acceptResult.bucketsToReenqueue)
            
            dequeuedBuckets.remove(dequeuedBucket)
            Logger.debug("Accepted result for bucket '\(testingResult.bucketId)' from '\(workerId)', updated dequeued buckets count: \(dequeuedBuckets.count)")
            for dequeuedBucket in dequeuedBuckets {
                Logger.verboseDebug(" -- \(dequeuedBucket)")
            }
            
            return BucketQueueAcceptResult(
                dequeuedBucket: dequeuedBucket,
                testingResultToCollect: acceptResult.testingResult
            )
        }
    }
    
    /// Removes and returns any buckets that appear to be stuck, providing a reason why queue thinks bucket is stuck.
    public func reenqueueStuckBuckets() -> [StuckBucket] {
        return queue.sync {
            let allDequeuedBuckets = dequeuedBuckets
            let stuckBuckets: [StuckBucket] = allDequeuedBuckets.compactMap { dequeuedBucket in
                let aliveness = workerAlivenessProvider.alivenessForWorker(workerId: dequeuedBucket.workerId)
                let stuckReason: StuckBucket.Reason
                switch aliveness.status {
                case .notRegistered:
                    Logger.fatal("Worker '\(dequeuedBucket.workerId)' is not registered, but stuck bucket has worker id of this worker. This is not expected, as we shouldn't dequeue bucket to non-registered workers.")
                case .alive:
                    if aliveness.bucketIdsBeingProcessed.contains(dequeuedBucket.enqueuedBucket.bucket.bucketId) {
                       return nil
                    }
                    stuckReason = .bucketLost
                case .blocked:
                    stuckReason = .workerIsBlocked
                case .silent(let lastAlivenessResponseTimestamp):
                    stuckReason = .workerIsSilent(since: lastAlivenessResponseTimestamp)
                }
                dequeuedBuckets.remove(dequeuedBucket)
                return StuckBucket(
                    reason: stuckReason,
                    bucket: dequeuedBucket.enqueuedBucket.bucket,
                    workerId: dequeuedBucket.workerId,
                    requestId: dequeuedBucket.requestId
                )
            }
            
            // Every stucked test produces a single bucket with itself
            let buckets = stuckBuckets.flatMap { stuckBucket in
                stuckBucket.bucket.testEntries.map { testEntry in
                    Bucket(
                        bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                        testEntries: [testEntry],
                        buildArtifacts: stuckBucket.bucket.buildArtifacts,
                        simulatorSettings: stuckBucket.bucket.simulatorSettings,
                        testDestination: stuckBucket.bucket.testDestination,
                        testExecutionBehavior: stuckBucket.bucket.testExecutionBehavior,
                        testType: stuckBucket.bucket.testType,
                        toolResources: stuckBucket.bucket.toolResources,
                        toolchainConfiguration: stuckBucket.bucket.toolchainConfiguration
                    )
                }
            }
            
            if !buckets.isEmpty {
                Logger.debug("Got \(stuckBuckets.count) stuck buckets, reenqueueing them as \(buckets.count) buckets:")
                for bucket in buckets {
                    Logger.debug("-- \(bucket)")
                }
                
                enqueue_onSyncQueue(buckets: buckets)
            }
            
            return stuckBuckets
        }
    }
    
    private func enqueue_onSyncQueue(buckets: [Bucket]) {
        // For empty queue it just inserts buckets to the beginning,
        //
        // There is an optimization to insert additional (probably failed) buckets:
        //
        // If we insert new buckets to the end of the queue we will end up in a situation when
        // there will be a tail of failing tests at the end of the queue.
        //
        // If we insert it in at the beginning there will be a little delay between retries,
        // and, for example, some temporarily unavalable service in E2E won't stop failing yet.
        //
        // The ideal solution is to optimize the inserting position based on current queue,
        // current number of retries etc. For example, spread retires evenly throughout whole run.
        //
        // This is not optimal:
        //
        let positionJustAfterNextBucket = 1
        
        let positionLimit = self.enqueuedBuckets.count
        let positionToInsert = min(positionJustAfterNextBucket, positionLimit)
        let enqueuedBuckets = buckets.map {
            EnqueuedBucket(
                bucket: $0,
                enqueueTimestamp: dateProvider.currentDate(),
                uniqueIdentifier: uniqueIdentifierGenerator.generate()
            )
        }
        self.enqueuedBuckets.insert(contentsOf: enqueuedBuckets, at: positionToInsert)
    }
    
    private func dequeue_onSyncQueue(enqueuedBucket: EnqueuedBucket, requestId: RequestId, workerId: WorkerId) -> DequeuedBucket {
        let dequeuedBucket = DequeuedBucket(enqueuedBucket: enqueuedBucket, workerId: workerId, requestId: requestId)
        
        enqueuedBuckets.removeAll(where: { $0 == enqueuedBucket })
        _ = dequeuedBuckets.insert(dequeuedBucket)
        
        Logger.debug("Dequeued new bucket: \(dequeuedBucket). Now there are \(dequeuedBuckets.count) dequeued buckets.")
        
        workerAlivenessProvider.didDequeueBucket(
            bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
            workerId: workerId
        )
        
        return dequeuedBucket
    }
    
    private func previouslyDequeuedBucket_onSyncQueue(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return dequeuedBuckets.first { $0.requestId == requestId && $0.workerId == workerId }
    }
    
    private func reenqueueLostResults_onSyncQueue(
        expectedTestEntries: Set<TestEntry>,
        actualTestEntries: Set<TestEntry>,
        bucket: Bucket,
        workerId: WorkerId,
        requestId: RequestId) throws
    {
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            Logger.debug("Test result from \(workerId) \(requestId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    bucketId: bucket.bucketId,
                    testDestination: bucket.testDestination,
                    unfilteredResults: lostTestEntries.map { TestEntryResult.lost(testEntry: $0) }),
                bucket: bucket,
                workerId: workerId
            )
            enqueue_onSyncQueue(buckets: lostResult.bucketsToReenqueue)
        }
    }
}
