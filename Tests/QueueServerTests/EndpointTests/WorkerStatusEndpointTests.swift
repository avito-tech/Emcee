import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueServer
import RESTMethods
import WorkerAlivenessModels
import WorkerAlivenessProvider
import XCTest

final class WorkerStatusEndpointTests: XCTestCase {
    lazy var bucketId = BucketId(value: "bucket")
    lazy var workerId = WorkerId(value: "worker")
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId],
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var endpoint = WorkerStatusEndpoint(workerAlivenessProvider: workerAlivenessProvider)
    
    func test() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [bucketId], workerId: workerId)
        
        let response = try endpoint.handle(payload: WorkerStatusPayload())
        
        XCTAssertEqual(
            response.workerAliveness,
            [
                workerId: WorkerAliveness(
                    registered: true,
                    bucketIdsBeingProcessed: [bucketId],
                    disabled: false,
                    silent: false,
                    workerUtilizationPermission: .allowedToUtilize
                )
            ]
        )
    }
}
