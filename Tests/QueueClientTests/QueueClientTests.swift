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
