import Foundation
import WorkerAlivenessTracker

public final class BucketQueueFactory {
    public static func create(workerAlivenessProvider: WorkerAlivenessProvider) -> BucketQueue {
        return BucketQueueImpl(workerAlivenessProvider: workerAlivenessProvider)
    }
}
