import DateProvider
import Foundation
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities

public final class SingleBucketQueueEnqueuerProvider: BucketEnqueuerProvider {
    private let dateProvider: DateProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage
    
    public init(
        dateProvider: DateProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage
    ) {
        self.dateProvider = dateProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }
    
    public func createBucketEnqueuer(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketEnqueuer {
        SingleBucketQueueEnqueuer(
            bucketQueueHolder: bucketQueueHolder,
            dateProvider: dateProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
    }
}
