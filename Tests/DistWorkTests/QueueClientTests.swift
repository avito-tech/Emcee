import DistWork
import Models
import RESTMethods
import Swifter
import SynchronousWaiter
import XCTest

class QueueClientTests: XCTestCase {
    
    private var server: HttpServer?
    private var port: Int!
    private var delegate: FakeQueueClientDelegate!
    private var queueClient: QueueClient!
    private let fakeToolResources = ToolResources(
        fbsimctl: FbsimctlLocation(.remoteUrl(URL(string: "http://example.com")!)),
        fbxctest: FbxctestLocation(.remoteUrl(URL(string: "http://example.com")!)))
    
    override func tearDown() {
        server?.stop()
        queueClient.close()
    }
    
    func prepareServer(_ query: String, _ response: @escaping (HttpRequest) -> (HttpResponse)) throws {
        do {
            server = HttpServer()
            server?[query] = response
            try server?.start(0)
            port = try server?.port() ?? 0
            delegate = FakeQueueClientDelegate()
            queueClient = QueueClient(serverAddress: "127.0.0.1", serverPort: port, workerId: "worker")
            queueClient.delegate = delegate
        } catch {
            XCTFail("Failed to prepare server: \(error)")
            throw error
        }
    }
    
    func testReturningEmptyQueue() throws {
        try prepareServer(RESTMethod.getBucket.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(RESTResponse.queueIsEmpty)) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchBucket(requestId: "id")
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
            testEntries: [TestEntry(className: "class", methodName: "method", caseId: 123)],
            testDestination: try TestDestination(deviceType: "device", iOSVersion: "10.0"),
            toolResources: fakeToolResources)
        try prepareServer(RESTMethod.getBucket.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(RESTResponse.bucketDequeued(bucket: bucket))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchBucket(requestId: "id")
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
            let data: Data = (try? JSONEncoder().encode(RESTResponse.checkAgainLater(checkAfter: 10.0))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.fetchBucket(requestId: "id")
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .checkAfter(let after):
            XCTAssertEqual(after, 10.0, accuracy: 0.1)
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func testRegisteringWorker() throws {
        let stubbedConfig = WorkerConfiguration(
            testExecutionBehavior: TestExecutionBehavior(
                numberOfRetries: 1,
                numberOfSimulators: 2,
                environment: ["env": "val"],
                scheduleStrategy: .progressive),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 666.6),
            reportAliveInterval: 5)
        
        try prepareServer(RESTMethod.registerWorker.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(RESTResponse.workerRegisterSuccess(workerConfiguration: stubbedConfig))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        try queueClient.registerWithServer()
        try SynchronousWaiter.waitWhile(timeout: 5.0) { delegate.responses.isEmpty }
        
        switch delegate.responses[0] {
        case .workerConfiguration(let configuration):
            XCTAssertEqual(
                stubbedConfig.testExecutionBehavior.numberOfRetries,
                configuration.testExecutionBehavior.numberOfRetries)
            XCTAssertEqual(
                stubbedConfig.testExecutionBehavior.numberOfSimulators,
                configuration.testExecutionBehavior.numberOfSimulators)
            XCTAssertEqual(
                stubbedConfig.testExecutionBehavior.environment,
                configuration.testExecutionBehavior.environment)
            XCTAssertEqual(
                stubbedConfig.testTimeoutConfiguration.singleTestMaximumDuration,
                configuration.testTimeoutConfiguration.singleTestMaximumDuration,
                accuracy: 0.1)
            XCTAssertEqual(
                stubbedConfig.testTimeoutConfiguration.singleTestMaximumDuration,
                configuration.testTimeoutConfiguration.singleTestMaximumDuration,
                accuracy: 0.1)
            XCTAssertEqual(
                stubbedConfig.reportAliveInterval,
                configuration.reportAliveInterval,
                accuracy: 0.1)
        default:
            XCTFail("Unexpected result")
        }
    }
    
    func testAliveRequests() throws {
        let stubbedConfig = WorkerConfiguration(
            testExecutionBehavior: TestExecutionBehavior(
                numberOfRetries: 1,
                numberOfSimulators: 2,
                environment: [:],
                scheduleStrategy: .progressive),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 666.6),
            reportAliveInterval: 0.5)
        
        try prepareServer(RESTMethod.registerWorker.withPrependingSlash) { request -> HttpResponse in
            let data: Data = (try? JSONEncoder().encode(RESTResponse.workerRegisterSuccess(workerConfiguration: stubbedConfig))) ?? Data()
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        }
        
        var didReceiveAliveRequest = false
        server?[RESTMethod.reportAlive.withPrependingSlash] = { _ in
            didReceiveAliveRequest = true
            return .accepted
        }
        
        try queueClient.registerWithServer()
        try SynchronousWaiter.waitWhile(timeout: 5.0) { !didReceiveAliveRequest }
        
        XCTAssertTrue(didReceiveAliveRequest)
    }
}
