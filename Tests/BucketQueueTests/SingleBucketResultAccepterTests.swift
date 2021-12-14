import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import TestHelpers
import TestHistoryTestHelpers
import TestHistoryTracker
import XCTest

final class SingleBucketResultAcceptorTests: XCTestCase {
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var testingResultAcceptor = FakeTestingResultAcceptor()
    lazy var accepter = SingleBucketResultAcceptor(
        bucketQueueHolder: bucketQueueHolder,
        logger: .noOp,
        testingResultAcceptor: testingResultAcceptor
    )
    
    func test___accepting_result_with_unknown_id_and_worker___throws_error() {
        assertThrows {
            _ = try accepter.accept(
                bucketId: "bucketId",
                bucketResult: .testingResult(TestingResultFixtures().testingResult()),
                workerId: "worker"
            )
        }
    }
    
    func test___accepting_result_with_known_bucket_id_and_matching_worker_id() {
        let runIosTestsPayload = BucketFixtures.createRunIosTestsPayload()
        let bucket = BucketFixtures.createBucket(bucketPayload: .runIosTests(runIosTestsPayload))
        let enqueuedBucket = EnqueuedBucket(
            bucket: bucket,
            enqueueTimestamp: Date(),
            uniqueIdentifier: "id"
        )
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: enqueuedBucket,
            workerId: "workerId"
        )
        
        bucketQueueHolder.add(dequeuedBucket: dequeuedBucket)
        
        assertDoesNotThrow {
            _ = try accepter.accept(
                bucketId: bucket.bucketId,
                bucketResult: .testingResult(
                    TestingResultFixtures()
                        .with(testEntry: runIosTestsPayload.testEntries[0])
                        .addingResult(success: true)
                        .testingResult()
                ),
                workerId: "workerId"
            )
        }
    }
}

extension BucketQueueHolder {
    func add(dequeuedBucket: DequeuedBucket) {
        insert(enqueuedBuckets: [dequeuedBucket.enqueuedBucket], position: 0)
        replacePreviouslyEnqueuedBucket(withDequeuedBucket: dequeuedBucket)
    }
}
