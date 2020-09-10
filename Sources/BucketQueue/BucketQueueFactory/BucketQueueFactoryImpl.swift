import DateProvider
import Foundation
import TestHistoryTracker
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities

public final class BucketQueueFactoryImpl: BucketQueueFactory {
    private let checkAgainTimeInterval: TimeInterval
    private let dateProvider: DateProvider
    private let testHistoryTracker: TestHistoryTracker
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let workerAlivenessProvider: WorkerAlivenessProvider
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
    
    public func createBucketQueue() -> BucketQueue {
        return BucketQueueImpl(
            checkAgainTimeInterval: checkAgainTimeInterval,
            dateProvider: dateProvider,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
    }
}
