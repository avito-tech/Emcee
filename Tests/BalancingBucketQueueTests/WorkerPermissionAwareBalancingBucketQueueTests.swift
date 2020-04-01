import BalancingBucketQueue
import QueueCommunication
import XCTest

class WorkerPermissionAwareBalancingBucketQueueTests: XCTestCase {
    let permissionProvider = FakeWorkerPermissionProvider()
    let queue = FakeBalancingBucketQueue()
    let behavior = NothingToDequeueBehaviorCheckLater(checkAfter: 1337)
    lazy var facade = WorkerPermissionAwareBalancingBucketQueue(
        workerPermissionProvider: permissionProvider,
        balancingBucketQueue: queue,
        nothingToDequeueBehavior: behavior
    )

    func test___dequeueBucket_when_worker_is_allowed_to_utilize___use_internal_queue_value() {
        permissionProvider.permission = .allowedToUtilize

        queue.dequeueBucketDequeueResult = .queueIsEmpty

        let result = facade.dequeueBucket(requestId: "RequestId", workerId: "WorkerId")

        XCTAssertEqual(result, .queueIsEmpty)
    }

    func test___dequeueBucket_when_worker_is_not_allowed_to_utilize___use_nothing_to_deque_value() {
        permissionProvider.permission = .notAllowedToUtilize

        queue.dequeueBucketDequeueResult = .queueIsEmpty

        let result = facade.dequeueBucket(requestId: "RequestId", workerId: "WorkerId")

        XCTAssertEqual(result, .checkAgainLater(checkAfter: 1337))
    }
}
