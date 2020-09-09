import BalancingBucketQueue
import BucketQueueTestHelpers
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import RunnerTestHelpers
import WorkerAlivenessProvider
import XCTest

final class BucketResultRegistrarTests: XCTestCase {
    lazy var alivenessTracker = WorkerAlivenessProviderImpl(
        knownWorkerIds: ["worker"],
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    let expectedPayloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    let testingResult = TestingResultFixtures()
        .with(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "method"))
        .addingLostResult()
        .testingResult()

    func test__results_collector_receives_results__if_bucket_queue_accepts_results() {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        
        let registrar = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature,
            workerAlivenessProvider: alivenessTracker
        )
        
        let request = BucketResultPayload(
            bucketId: "bucket id",
            workerId: "worker",
            testingResult: testingResult,
            payloadSignature: expectedPayloadSignature
        )
        XCTAssertNoThrow(try registrar.handle(payload: request))
        
        XCTAssertEqual(bucketQueue.acceptedResults, [testingResult])
    }
    
    func test___results_collector_stays_unmodified___if_bucket_queue_does_not_accept_results() {
        alivenessTracker.didRegisterWorker(workerId: "worker")
        let bucketQueue = FakeBucketQueue(throwsOnAccept: true)
        
        let registrar = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature,
            workerAlivenessProvider: alivenessTracker
        )
        
        let request = BucketResultPayload(
            bucketId: "bucket id",
            workerId: "worker",
            testingResult: testingResult,
            payloadSignature: expectedPayloadSignature
        )
        XCTAssertThrowsError(try registrar.handle(payload: request))
        
        XCTAssertEqual(bucketQueue.acceptedResults, [])
    }

    func test___throws___when_expected_request_signature_mismatch() {
        alivenessTracker.didRegisterWorker(workerId: "worker")
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)

        let registrar = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature,
            workerAlivenessProvider: alivenessTracker
        )

        XCTAssertThrowsError(
            try registrar.handle(
                payload: BucketResultPayload(
                    bucketId: "bucket id",
                    workerId: "worker",
                    testingResult: testingResult,
                    payloadSignature: PayloadSignature(value: UUID().uuidString)
                )
            ),
            "When payload signature mismatches, bucket provider endpoind should throw"
        )
    }
}

