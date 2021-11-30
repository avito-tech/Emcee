import EmceeLogging
import Foundation
import TestHistoryTracker

public final class SingleBucketResultAccepterProvider: BucketResultAccepterProvider {
    private let bucketEnqueuerProvider: BucketEnqueuerProvider
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    
    public init(
        bucketEnqueuerProvider: BucketEnqueuerProvider,
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker
    ) {
        self.bucketEnqueuerProvider = bucketEnqueuerProvider
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
    }
    
    public func createBucketResultAccepter(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketResultAccepter {
        SingleBucketResultAccepter(
            bucketEnqueuer: bucketEnqueuerProvider.createBucketEnqueuer(
                bucketQueueHolder: bucketQueueHolder
            ),
            bucketQueueHolder: bucketQueueHolder,
            logger: logger,
            testHistoryTracker: testHistoryTracker
        )
    }
}
