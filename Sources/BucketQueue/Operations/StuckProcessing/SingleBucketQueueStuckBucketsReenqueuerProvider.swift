import EmceeLogging
import Foundation
import WorkerAlivenessProvider
import UniqueIdentifierGenerator

public final class SingleBucketQueueStuckBucketsReenqueuerProvider: StuckBucketsReenqueuerProvider {
    private let logger: ContextualLogger
    private let bucketEnqueuerProvider: BucketEnqueuerProvider
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        logger: ContextualLogger,
        bucketEnqueuerProvider: BucketEnqueuerProvider,
        workerAlivenessProvider: WorkerAlivenessProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.logger = logger
        self.bucketEnqueuerProvider = bucketEnqueuerProvider
        self.workerAlivenessProvider = workerAlivenessProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func createStuckBucketsReenqueuer(
        bucketQueueHolder: BucketQueueHolder
    ) -> StuckBucketsReenqueuer {
        SingleBucketQueueStuckBucketsReenqueuer(
            bucketEnqueuer: bucketEnqueuerProvider.createBucketEnqueuer(
                bucketQueueHolder: bucketQueueHolder
            ),
            bucketQueueHolder: bucketQueueHolder,
            logger: logger,
            workerAlivenessProvider: workerAlivenessProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
}
