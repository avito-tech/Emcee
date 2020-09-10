import BalancingBucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModelsTestHelpers
import QueueServer
import XCTest

final class WorkerPermissionAwareDequeueableBucketSourceTests: XCTestCase {
    let permissionProvider = FakeWorkerPermissionProvider()
    
    lazy var dequeuedBucket = DequeuedBucket(
        enqueuedBucket: EnqueuedBucket(
            bucket: BucketFixtures.createBucket(),
            enqueueTimestamp: Date(),
            uniqueIdentifier: "id"
        ),
        workerId: "workerId"
    )
    lazy var bucketSource = WorkerPermissionAwareDequeueableBucketSource(
        dequeueableBucketSource: FakeDequeueableBucketSource(
            dequeuedBucket: dequeuedBucket
        ),
        workerPermissionProvider: permissionProvider
    )

    func test___dequeueBucket_when_worker_is_allowed_to_utilize___use_internal_queue_value() {
        permissionProvider.permission = .allowedToUtilize

        let result = bucketSource.dequeueBucket(workerCapabilities: [], workerId: "WorkerId")

        XCTAssertEqual(result, dequeuedBucket)
    }

    func test___dequeueBucket_when_worker_is_not_allowed_to_utilize___use_nothing_to_deque_value() {
        permissionProvider.permission = .notAllowedToUtilize

        let result = bucketSource.dequeueBucket(workerCapabilities: [], workerId: "WorkerId")

        XCTAssertEqual(result, nil)
    }
}
