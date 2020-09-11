import BucketQueue
import BucketQueueModels
import DateProviderTestHelpers
import Foundation
import TestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueCommunicationTestHelpers
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class SingleBucketQueueEnqueuerTests: XCTestCase {
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var dateProvder = DateProviderFixture()
    lazy var workerPermissionProvider = FakeWorkerPermissionProvider()
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId],
        workerPermissionProvider: workerPermissionProvider
    )
    lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    lazy var workerId = WorkerId("workerId")
    
    lazy var enqueuer = SingleBucketQueueEnqueuer(
        bucketQueueHolder: bucketQueueHolder,
        dateProvider: dateProvder,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator,
        workerAlivenessProvider: workerAlivenessProvider,
        workerCapabilitiesStorage: workerCapabilitiesStorage
    )
    
    func test___throws___when_no_suitable_workers_are_available() {
        let bucket = BucketFixtures.createBucket()
        assertThrows {
            try enqueuer.enqueue(buckets: [bucket])
        }
    }
    
    func test___enqueues___when_suitable_worker_is_available() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let bucket = BucketFixtures.createBucket()
        assertDoesNotThrow {
            try enqueuer.enqueue(buckets: [bucket])
        }
        
        XCTAssertEqual(
            bucketQueueHolder.allEnqueuedBuckets,
            [
                EnqueuedBucket(
                    bucket: bucket,
                    enqueueTimestamp: dateProvder.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                )
            ]
        )
    }
    
    func test___validating_bucket_for_requirements___throws_when_capabilities_mismatch() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let bucket = BucketFixtures.createBucket(
            workerCapabilityRequirements: [
                WorkerCapabilityRequirement(capabilityName: "name", constraint: .present)
            ]
        )
        
        assertThrows {
            try enqueuer.enqueue(buckets: [bucket])
        }
    }
    
    func test___validating_bucket_for_requirements___enqueues_when_capabilities_match() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        workerCapabilitiesStorage.set(
            workerCapabilities: [WorkerCapability(name: "name", value: "something")],
            forWorkerId: workerId
        )
        
        let bucket = BucketFixtures.createBucket(
            workerCapabilityRequirements: [
                WorkerCapabilityRequirement(capabilityName: "name", constraint: .present)
            ]
        )
        
        assertDoesNotThrow {
            try enqueuer.enqueue(buckets: [bucket])
        }
    }
}

