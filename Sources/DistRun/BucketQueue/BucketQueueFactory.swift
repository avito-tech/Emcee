import Foundation
import WorkerAlivenessTracker

public final class BucketQueueFactory {
    public static func create(
        workerAlivenessTracker: WorkerAlivenessTracker,
        workerRegistrar: WorkerRegistrar)
        -> BucketQueue
    {
        return BucketQueueImpl(workerAlivenessTracker: workerAlivenessTracker, workerRegistrar: workerRegistrar)
    }
}
