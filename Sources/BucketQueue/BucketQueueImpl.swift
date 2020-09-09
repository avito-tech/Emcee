import DateProvider
import Dispatch
import Foundation
import Logging
import QueueModels
import RunnerModels
import Types
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels

final class BucketQueueImpl: BucketQueue {
    private let dateProvider: DateProvider
    private var enqueuedBuckets = [EnqueuedBucket]()
    private var dequeuedBuckets = Set<DequeuedBucket>()
    private let testHistoryTracker: TestHistoryTracker
    private let queue = DispatchQueue(label: "ru.avito.emcee.BucketQueue.queue")
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let checkAgainTimeInterval: TimeInterval
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let workerCapabilityConstraintResolver = WorkerCapabilityConstraintResolver()
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage
    
    public init(
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        testHistoryTracker: TestHistoryTracker,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage
    ) {
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.dateProvider = dateProvider
        self.testHistoryTracker = testHistoryTracker
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }
    
    public func enqueue(buckets: [Bucket]) throws {
        try validate(buckets: buckets)
        
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
        var dequeuedTests = MapWithCollection<WorkerId, TestName>()
        for dequeuedBucket in dequeuedBuckets {
            dequeuedTests.append(
                key: dequeuedBucket.workerId,
                elements: dequeuedBucket.enqueuedBucket.bucket.testEntries.map { $0.testName }
            )
        }
        
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBuckets.count,
            enqueuedTests: enqueuedBuckets.flatMap { $0.bucket.testEntries.map { $0.testName } },
            dequeuedBucketCount: dequeuedBuckets.count,
            dequeuedTests: dequeuedTests
        )
    }
        
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
        workerAlivenessProvider.willDequeueBucket(workerId: workerId)
        workerCapabilitiesStorage.set(workerCapabilities: workerCapabilities, forWorkerId: workerId)
        
        guard workerAlivenessProvider.isWorkerRegistered(workerId: workerId) else {
            return .workerIsNotRegistered
        }
        
        guard workerAlivenessProvider.isWorkerEnabled(workerId: workerId) else {
            return .checkAgainLater(checkAfter: checkAgainTimeInterval)
        }

        return queue.sync {
            if runningQueueState_onSyncQueue.isDepleted {
                return .queueIsEmpty
            }
            if runningQueueState_onSyncQueue.enqueuedTests.isEmpty {
                return .checkAgainLater(checkAfter: checkAgainTimeInterval)
            }
            
            let bucketToDequeueOrNil = testHistoryTracker.bucketToDequeue(
                workerId: workerId,
                queue: enqueuedBuckets,
                workerIdsInWorkingCondition: workerAlivenessProvider.workerIdsInWorkingCondition
            )
            
            if let enqueuedBucket = bucketToDequeueOrNil {
                guard workerCapabilityConstraintResolver.requirementsSatisfied(
                    requirements: enqueuedBucket.bucket.workerCapabilityRequirements,
                    workerCapabilities: workerCapabilities
                ) else {
                    Logger.debug("capabilities \(workerCapabilities) of \(workerId) do not meet bucket requirements: \(enqueuedBucket.bucket.workerCapabilityRequirements)")
                    return .checkAgainLater(checkAfter: checkAgainTimeInterval)
                }
                
                return .dequeuedBucket(
                    dequeue_onSyncQueue(
                        enqueuedBucket: enqueuedBucket,
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
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        return try queue.sync {
            Logger.debug("Validating result for \(bucketId) from \(workerId): \(testingResult)")
            
            guard let dequeuedBucket = previouslyDequeuedBucket_onSyncQueue(bucketId: bucketId, workerId: workerId) else {
                Logger.verboseDebug("Validation failed: no dequeued bucket for \(bucketId) \(workerId)")
                throw ResultAcceptanceError.noDequeuedBucket(bucketId: bucketId, workerId: workerId)
            }
            
            let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
            let expectedTestEntries = Set(dequeuedBucket.enqueuedBucket.bucket.testEntries)
            try reenqueueLostResults_onSyncQueue(
                expectedTestEntries: expectedTestEntries,
                actualTestEntries: actualTestEntries,
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: workerId
            )
            
            let acceptResult = try testHistoryTracker.accept(
                testingResult: testingResult,
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: workerId
            )
            enqueue_onSyncQueue(buckets: acceptResult.bucketsToReenqueue)
            
            dequeuedBuckets.remove(dequeuedBucket)
            Logger.debug("Accepted result for \(dequeuedBucket.enqueuedBucket.bucket.bucketId) from \(workerId), updated dequeued buckets count: \(dequeuedBuckets.count)")
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
                if !aliveness.registered {
                    Logger.fatal("Worker '\(dequeuedBucket.workerId)' is not registered, but stuck bucket has worker id of this worker. This is not expected, as we shouldn't dequeue bucket to non-registered workers.")
                }
                
                let stuckReason: StuckBucket.Reason
                if aliveness.isInWorkingCondition {
                    if aliveness.bucketIdsBeingProcessed.contains(dequeuedBucket.enqueuedBucket.bucket.bucketId) {
                       return nil
                    }
                    stuckReason = .bucketLost
                } else if aliveness.silent {
                    stuckReason = .workerIsSilent
                } else {
                    return nil
                }
                
                dequeuedBuckets.remove(dequeuedBucket)
                return StuckBucket(
                    reason: stuckReason,
                    bucket: dequeuedBucket.enqueuedBucket.bucket,
                    workerId: dequeuedBucket.workerId
                )
            }
            
            // Every stucked test produces a single bucket with itself
            let buckets = stuckBuckets.flatMap { stuckBucket in
                stuckBucket.bucket.testEntries.map { testEntry in
                    Bucket(
                        bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                        buildArtifacts: stuckBucket.bucket.buildArtifacts,
                        developerDir: stuckBucket.bucket.developerDir,
                        pluginLocations: stuckBucket.bucket.pluginLocations,
                        simulatorControlTool: stuckBucket.bucket.simulatorControlTool,
                        simulatorOperationTimeouts: stuckBucket.bucket.simulatorOperationTimeouts,
                        simulatorSettings: stuckBucket.bucket.simulatorSettings,
                        testDestination: stuckBucket.bucket.testDestination,
                        testEntries: [testEntry],
                        testExecutionBehavior: stuckBucket.bucket.testExecutionBehavior,
                        testRunnerTool: stuckBucket.bucket.testRunnerTool,
                        testTimeoutConfiguration: stuckBucket.bucket.testTimeoutConfiguration,
                        testType: stuckBucket.bucket.testType,
                        workerCapabilityRequirements: stuckBucket.bucket.workerCapabilityRequirements
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
    
    private func dequeue_onSyncQueue(enqueuedBucket: EnqueuedBucket, workerId: WorkerId) -> DequeuedBucket {
        let dequeuedBucket = DequeuedBucket(enqueuedBucket: enqueuedBucket, workerId: workerId)
        
        enqueuedBuckets.removeAll(where: { $0 == enqueuedBucket })
        _ = dequeuedBuckets.insert(dequeuedBucket)
        
        Logger.debug("Dequeued new bucket: \(dequeuedBucket). Now there are \(dequeuedBuckets.count) dequeued buckets.")
        
        workerAlivenessProvider.didDequeueBucket(
            bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
            workerId: workerId
        )
        
        return dequeuedBucket
    }
    
    private func previouslyDequeuedBucket_onSyncQueue(bucketId: BucketId, workerId: WorkerId) -> DequeuedBucket? {
        return dequeuedBuckets.first { $0.enqueuedBucket.bucket.bucketId == bucketId && $0.workerId == workerId }
    }
    
    private func reenqueueLostResults_onSyncQueue(
        expectedTestEntries: Set<TestEntry>,
        actualTestEntries: Set<TestEntry>,
        bucket: Bucket,
        workerId: WorkerId
    ) throws {
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            Logger.debug("Test result for \(bucket.bucketId) from \(workerId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    testDestination: bucket.testDestination,
                    unfilteredResults: lostTestEntries.map { TestEntryResult.lost(testEntry: $0) }
                ),
                bucket: bucket,
                workerId: workerId
            )
            enqueue_onSyncQueue(buckets: lostResult.bucketsToReenqueue)
        }
    }
    
    private func validate(buckets: [Bucket]) throws {
        struct BucketValidationError: Error, CustomStringConvertible {
            let buckets: [Bucket]
            
            var description: String {
                buckets.map {
                    "Bucket with \($0.bucketId) is not runnable because bucket requirements can't be met: \($0.workerCapabilityRequirements)"
                }.joined(separator: "; ")
            }
        }
        
        let allWorkerCapabilities = workerAlivenessProvider.workerAliveness
            .filter { $0.value.isInWorkingCondition }
            .map { workerCapabilitiesStorage.workerCapabilities(forWorkerId: $0.key) }

        let bucketsWithNotSatisifiedRequirements = buckets.filter { bucket -> Bool in
            !allWorkerCapabilities.contains { workerCapabilities in
                workerCapabilityConstraintResolver.requirementsSatisfied(
                    requirements: bucket.workerCapabilityRequirements,
                    workerCapabilities: workerCapabilities
                )
            }
        }
        if !bucketsWithNotSatisifiedRequirements.isEmpty {
            throw BucketValidationError(buckets: bucketsWithNotSatisifiedRequirements)
        }
    }
}
