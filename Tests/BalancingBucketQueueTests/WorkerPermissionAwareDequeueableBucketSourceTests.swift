import BalancingBucketQueue
import BucketQueueTestHelpers
import QueueCommunication
import QueueCommunicationTestHelpers
import XCTest

final class WorkerPermissionAwareDequeueableBucketSourceTests: XCTestCase {
    let permissionProvider = FakeWorkerPermissionProvider()
    let behavior = NothingToDequeueBehaviorCheckLater(checkAfter: 1337)
    lazy var bucketSource = WorkerPermissionAwareDequeueableBucketSource(
        dequeueableBucketSource: FakeDequeueableBucketSource(
            dequeueResult: .queueIsEmpty,
            previouslyDequeuedBucket: nil
        ),
        nothingToDequeueBehavior: behavior,
        workerPermissionProvider: permissionProvider
    )

    func test___dequeueBucket_when_worker_is_allowed_to_utilize___use_internal_queue_value() {
        permissionProvider.permission = .allowedToUtilize

        let result = bucketSource.dequeueBucket(requestId: "RequestId", workerId: "WorkerId")

        XCTAssertEqual(result, .queueIsEmpty)
    }

    func test___dequeueBucket_when_worker_is_not_allowed_to_utilize___use_nothing_to_deque_value() {
        permissionProvider.permission = .notAllowedToUtilize

        let result = bucketSource.dequeueBucket(requestId: "RequestId", workerId: "WorkerId")

        XCTAssertEqual(result, .checkAgainLater(checkAfter: 1337))
    }
}
