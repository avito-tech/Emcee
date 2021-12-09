import EmceeLogging
import Foundation
import TestHistoryTracker

public final class SingleBucketResultAcceptorProvider: BucketResultAcceptorProvider {
    private let logger: ContextualLogger
    private let testingResultAcceptorProvider: TestingResultAcceptorProvider
    
    public init(
        logger: ContextualLogger,
        testingResultAcceptorProvider: TestingResultAcceptorProvider
    ) {
        self.logger = logger
        self.testingResultAcceptorProvider = testingResultAcceptorProvider
    }
    
    public func createBucketResultAcceptor(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketResultAcceptor {
        SingleBucketResultAcceptor(
            bucketQueueHolder: bucketQueueHolder,
            logger: logger,
            testingResultAcceptor: testingResultAcceptorProvider.create(
                bucketQueueHolder: bucketQueueHolder
            )
        )
    }
}
