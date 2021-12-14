import EmceeLogging
import Foundation
import TestHistoryTracker
import UniqueIdentifierGenerator

public final class TestingResultAcceptorProviderImpl: TestingResultAcceptorProvider {
    private let bucketEnqueuerProvider: BucketEnqueuerProvider
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        bucketEnqueuerProvider: BucketEnqueuerProvider,
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.bucketEnqueuerProvider = bucketEnqueuerProvider
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func create(
        bucketQueueHolder: BucketQueueHolder
    ) -> TestingResultAcceptor {
        TestingResultAcceptorImpl(
            bucketEnqueuer: bucketEnqueuerProvider.createBucketEnqueuer(
                bucketQueueHolder: bucketQueueHolder
            ),
            bucketQueueHolder: bucketQueueHolder,
            logger: logger,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
}
