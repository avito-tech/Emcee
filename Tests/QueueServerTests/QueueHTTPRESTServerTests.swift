import BucketQueue
import BucketQueueTestHelpers
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import PortDeterminer
import QueueClient
import QueueServer
import RESTMethods
import ResultsCollector
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class QueueHTTPRESTServerTests: XCTestCase {
    let restServer = QueueHTTPRESTServer(localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange))
    let workerConfigurations = WorkerConfigurations()
    let workerId = "worker"
    let requestId = "requestId"
    let queueServerAddress = "localhost"
    
    let stubbedEndpoint = FakeRESTEndpoint<Int, Int>(0)
    
    override func setUp() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    func test__RegisterWorkerHandler() throws {
        let workerRegistrar = WorkerRegistrar(
            workerConfigurations: workerConfigurations,
            workerAlivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults())
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: stubbedEndpoint)
        )
        let port = try restServer.start()
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        
        XCTAssertEqual(try client.registerWithServer(), WorkerConfigurationFixtures.workerConfiguration)
    }
    
    func test__BucketFetchHandler() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [
            TestEntry(className: "class1", methodName: "m1", caseId: nil),
            TestEntry(className: "class2", methodName: "m2", caseId: nil)])
        let dequeuedBucket = DequeuedBucket(bucket: bucket, workerId: workerId, requestId: requestId)
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: DequeueResult.dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(
            bucketQueue: bucketQueue,
            alivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        )
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: stubbedEndpoint)
        )
        let port = try restServer.start()
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        
        let fetchResult = try client.fetchBucket(requestId: requestId)
        XCTAssertEqual(fetchResult, SynchronousQueueClient.BucketFetchResult.bucket(bucket))
    }
    
    func test__ResultHandler() throws {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        let testingResult = TestingResultFixtures()
            .with(testEntry: TestEntry(className: "class1", methodName: "m1", caseId: nil))
            .addingLostResult()
            .with(testEntry: TestEntry(className: "class2", methodName: "m2", caseId: nil))
            .addingLostResult()
            .testingResult()
        
        let resultsCollector = ResultsCollector()
        
        let resultHandler = BucketResultRegistrar(
            bucketQueue: bucketQueue,
            eventBus: EventBus(),
            resultsCollector: resultsCollector,
            workerAlivenessTracker: alivenessTracker)
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            bucketResultHandler: RESTEndpointOf(actualHandler: resultHandler),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: stubbedEndpoint)
        )
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        _ = try client.send(testingResult: testingResult, requestId: requestId)
        
        XCTAssertEqual(resultsCollector.collectedResults, [testingResult])
    }
    
    func test__ReportAliveHandler() throws {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: WorkerAlivenessEndpoint(alivenessTracker: alivenessTracker)),
            versionHandler: RESTEndpointOf(actualHandler: stubbedEndpoint)
        )
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        try client.reportAliveness { [] }
        
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId).status, .alive)
    }
    
    func test__QueueServerVersion() throws {
        let versionHandler = FakeRESTEndpoint<QueueVersionRequest, QueueVersionResponse>(QueueVersionResponse.queueVersion("abc"))
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: versionHandler)
        )
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)

        XCTAssertEqual(
            try client.fetchQueueServerVersion(),
            "abc"
        )
    }
}
