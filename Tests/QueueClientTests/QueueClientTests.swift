import BuildArtifactsTestHelpers
import QueueClient
import QueueModels
import QueueModelsTestHelpers
import RESTInterfaces
import RESTMethods
import RequestSender
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import SocketModels
import Swifter
import SynchronousWaiter
import XCTest

class QueueClientTests: XCTestCase {
    
    private var server = HttpServer()
    private var port: SocketModels.Port = 0
    private let delegate = FakeQueueClientDelegate()
    private var queueClient: QueueClient!
    private let workerId = WorkerId(value: "workerId")
    private let payloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    
    override func tearDown() {
        server.stop()
        queueClient.close()
    }
    
    func prepareServer(_ query: String, _ response: @escaping (HttpRequest) -> (HttpResponse)) throws {
        do {
            server[query] = response
            try server.start(0)
            port = SocketModels.Port(value: try server.port())
            queueClient = QueueClient(
                queueServerAddress: SocketAddress(host: "127.0.0.1", port: port),
                requestSenderProvider: DefaultRequestSenderProvider()
            )
            queueClient.delegate = delegate
        } catch {
            XCTFail("Failed to prepare server: \(error)")
            throw error
        }
    }
    
    func test___scheduling_tests() throws {
        let serverHasProvidedResponseExpectation = expectation(description: "Server provided response")
        let prioritizedJob = PrioritizedJob(jobGroupId: "groupId", jobGroupPriority: .medium, jobId: "jobid", jobPriority: .medium)
        let requestId: RequestId = "requestId"
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry())
            .testEntryConfigurations()
        
        try prepareServer(RESTMethod.scheduleTests.pathWithLeadingSlash) { request -> HttpResponse in
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
                    scheduleStrategy: .individual,
                    testEntryConfigurations: testEntryConfigurations
                )
            )
            
            let data: Data = (try? JSONEncoder().encode(ScheduleTestsResponse.scheduledTests(requestId: requestId))) ?? Data()
            
            defer { serverHasProvidedResponseExpectation.fulfill() }
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        
        try queueClient.scheduleTests(
            prioritizedJob: prioritizedJob,
            scheduleStrategy: .individual,
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
        try prepareServer(RESTMethod.jobState.pathWithLeadingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(JobStateResponse(jobState: jobState))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchJobState(jobId: jobId)
        try SynchronousWaiter().waitWhile(timeout: 5.0, description: "wait for response") { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .fetchedJobState(let fetchedJobState):
            XCTAssertEqual(fetchedJobState, jobState)
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func test___deleting_job() throws {
        let jobId: JobId = "job_id"
        try prepareServer(RESTMethod.jobDelete.pathWithLeadingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(JobDeleteResponse(jobId: jobId))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.deleteJob(jobId: jobId)
        try SynchronousWaiter().waitWhile(timeout: 5.0, description: "wait for response") { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .deletedJob(let deletedJobId):
            XCTAssertEqual(jobId, deletedJobId)
        default:
            XCTFail("Unexpected result")
        }
    }
}
