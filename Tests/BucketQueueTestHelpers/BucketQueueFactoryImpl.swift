import DateProvider
import EmceeLogging
import Foundation
import TestHistoryTracker
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities

public final class BucketQueueFactoryImpl {
    private let dateProvider: DateProvider
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage

    public init(
        dateProvider: DateProvider,
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage
    ) {
        self.dateProvider = dateProvider
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }
    
    public func createBucketQueue() -> BucketQueueImpl {
        return BucketQueueImpl(
            dateProvider: dateProvider,
            logger: logger,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
    }
}
