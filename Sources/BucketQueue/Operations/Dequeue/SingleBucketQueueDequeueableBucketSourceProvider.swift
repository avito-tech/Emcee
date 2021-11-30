import EmceeLogging
import Foundation
import TestHistoryTracker
import WorkerAlivenessProvider
import WorkerCapabilities

public final class SingleBucketQueueDequeueableBucketSourceProvider: DequeueableBucketSourceProvider {
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage
    private let workerCapabilityConstraintResolver: WorkerCapabilityConstraintResolver
    
    public init(
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage,
        workerCapabilityConstraintResolver: WorkerCapabilityConstraintResolver
    ) {
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
        self.workerCapabilityConstraintResolver = workerCapabilityConstraintResolver
    }
    
    public func createDequeueableBucketSource(
        bucketQueueHolder: BucketQueueHolder
    ) -> DequeueableBucketSource {
        SingleBucketQueueDequeueableBucketSource(
            bucketQueueHolder: bucketQueueHolder,
            logger: logger,
            testHistoryTracker: testHistoryTracker,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
    }
}
