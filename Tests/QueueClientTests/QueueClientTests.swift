import Models
import ModelsTestHelpers
import QueueClient
import RESTMethods
import Swifter
import SynchronousWaiter
import XCTest

class QueueClientTests: XCTestCase {
    
    private var server = HttpServer()
    private var port: Int = 0
    private let delegate = FakeQueueClientDelegate()
    private var queueClient: QueueClient!
    private let workerId = WorkerId(value: "workerId")
    private let requestSignature = RequestSignature(value: "expectedRequestSignature")
    
    override func tearDown() {
        server.stop()
        queueClient.close()
    }
    
    func prepareServer(_ query: String, _ response: @escaping (HttpRequest) -> (HttpResponse)) throws {
        do {
            server[query] = response
            try server.start(0)
            port = try server.port()
            queueClient = QueueClient(queueServerAddress: SocketAddress(host: "127.0.0.1", port: port))
            queueClient.delegate = delegate
        } catch {
            XCTFail("Failed to prepare server: \(error)")
            throw error
        }
    }
    
    func testReturningEmptyQueue() throws {
        try prepareServer(RESTMethod.getBucket.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(DequeueBucketResponse.queueIsEmpty)) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchBucket(requestId: "id", workerId: workerId, requestSignature: requestSignature)
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .queueIsEmpty:
            return
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func testDequeueingBucket() throws {
        let bucket = Bucket(
            bucketId: BucketId(value: UUID().uuidString),
            testEntries: [TestEntryFixtures.testEntry(className: "class", methodName: "method")],
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
            testType: .uiTest,
            toolResources: ToolResourcesFixtures.fakeToolResources(),
            toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
        )
        try prepareServer(RESTMethod.getBucket.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(DequeueBucketResponse.bucketDequeued(bucket: bucket))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchBucket(requestId: "id", workerId: workerId, requestSignature: requestSignature)
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .bucket(let dequeuedBucket):
            XCTAssertEqual(bucket, dequeuedBucket)
            return
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func testCheckAgainLater() throws {
        try prepareServer(RESTMethod.getBucket.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(DequeueBucketResponse.checkAgainLater(checkAfter: 10.0))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchBucket(requestId: "id", workerId: workerId, requestSignature: requestSignature)
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .checkAfter(let after):
            XCTAssertEqual(after, 10.0, accuracy: 0.1)
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func testRegisteringWorker() throws {
        let stubbedConfig = WorkerConfigurationFixtures.workerConfiguration
        
        try prepareServer(RESTMethod.registerWorker.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(RegisterWorkerResponse.workerRegisterSuccess(workerConfiguration: stubbedConfig))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.registerWithServer(workerId: workerId)
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .workerConfiguration(let configuration):
            XCTAssertEqual(stubbedConfig, configuration, "Response should have the provided worker configuration")
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func testAliveRequests() throws {
        let alivenessReportReceivedExpectation = self.expectation(description: "Aliveness report has been received")
        let bucketIdsProviderCalledExpectation = self.expectation(description: "Bucket Ids provider used")
        
        let bucketId = BucketId(stringLiteral: UUID().uuidString)
        let provider: () -> Set<BucketId> = {
            bucketIdsProviderCalledExpectation.fulfill()
            return Set([bucketId])
        }
        
        try prepareServer(RESTMethod.reportAlive.withPrependingSlash) { request -> HttpResponse in
            defer { alivenessReportReceivedExpectation.fulfill() }
            
            let requestData = Data(request.body)
            let body = try? JSONDecoder().decode(ReportAliveRequest.self, from: requestData)
            XCTAssertEqual(body?.bucketIdsBeingProcessed, [bucketId])
            
            let data: Data = (try? JSONEncoder().encode(ReportAliveResponse.aliveReportAccepted)) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        
        try queueClient.reportAlive(
            bucketIdsBeingProcessedProvider: provider(),
            workerId: workerId,
            requestSignature: requestSignature,
            completion: { result in
                XCTAssertNoThrow(
                    try! {
                        let response = try result.dematerialize()
                        XCTAssertEqual(response, ReportAliveResponse.aliveReportAccepted)
                    }()
                )
            }
        )
        
        wait(for: [alivenessReportReceivedExpectation, bucketIdsProviderCalledExpectation], timeout: 10)
    }
    
    func test___when_queue_is_closed___requests_throw_correct_error() throws {
        try prepareServer(RESTMethod.getBucket.withPrependingSlash) { request -> HttpResponse in
            XCTFail("Endpoint should not be called")
            return .internalServerError
        }
        queueClient.close()
        XCTAssertThrowsError(
            try queueClient.fetchBucket(requestId: "id", workerId: workerId, requestSignature: requestSignature),
            "Closed queue client should throw"
        ) { throwedError in
            guard let error = throwedError as? QueueClientError else {
                XCTFail("Unexpected error: \(throwedError)")
                return
            }
            switch error {
            case .queueClientIsClosed(let method):
                XCTAssertEqual(method, RESTMethod.getBucket)
            default:
                XCTFail("Unexpected error: \(throwedError)")
            }
        }
    }
    
    func test___scheduling_tests() throws {
        let serverHasProvidedResponseExpectation = expectation(description: "Server provided response")
        let prioritizedJob = PrioritizedJob(jobId: "jobid", priority: .medium)
        let requestId: RequestId = "requestId"
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry())
            .testEntryConfigurations()
        
        try prepareServer(RESTMethod.scheduleTests.withPrependingSlash) { request -> HttpResponse in
            let requestData = Data(request.body)
            guard let body = try? JSONDecoder().decode(ScheduleTestsRequest.self, from: requestData) else {
                XCTFail("Queue client request has unexpected type")
                serverHasProvidedResponseExpectation.isInverted = true
                serverHasProvidedResponseExpectation.fulfill()
                return .internalServerError
            }
            XCTAssertEqual(
                body,
                ScheduleTestsRequest(
                    requestId: requestId,
                    prioritizedJob: prioritizedJob,
                    testEntryConfigurations: testEntryConfigurations
                )
            )
            
            let data: Data = (try? JSONEncoder().encode(ScheduleTestsResponse.scheduledTests(requestId: requestId))) ?? Data()
            
            defer { serverHasProvidedResponseExpectation.fulfill() }
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        
        try queueClient.scheduleTests(
            prioritizedJob: prioritizedJob,
            testEntryConfigurations: testEntryConfigurations,
            requestId: requestId
        )
        
        wait(for: [serverHasProvidedResponseExpectation], timeout: 10)
    }
    
    func test___job_state() throws {
        let jobId: JobId = "job_id"
        let jobState = JobState(
            jobId: jobId,
            queueState: QueueState.running(
                RunningQueueStateFixtures.runningQueueState()
            )
        )
        try prepareServer(RESTMethod.jobState.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(JobStateResponse(jobState: jobState))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchJobState(jobId: jobId)
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .fetchedJobState(let fetchedJobState):
            XCTAssertEqual(fetchedJobState, jobState)
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func test___deleting_job() throws {
        let jobId: JobId = "job_id"
        try prepareServer(RESTMethod.jobDelete.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(JobDeleteResponse(jobId: jobId))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.deleteJob(jobId: jobId)
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .deletedJob(let deletedJobId):
            XCTAssertEqual(jobId, deletedJobId)
        default:
            XCTFail("Unexpected result")
        }
    }
}
