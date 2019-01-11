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
import ScheduleStrategy
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class QueueHTTPRESTServerTests: XCTestCase {
    let restServer = QueueHTTPRESTServer(localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange))
    let workerConfigurations = WorkerConfigurations()
    let workerId = "worker"
    let requestId = "requestId"
    let queueServerAddress = "localhost"
    let jobId: JobId = "JobId"
    
    let stubbedEndpoint = FakeRESTEndpoint<Int, Int>(0)
    
    override func setUp() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    func test__RegisterWorkerHandler() throws {
        let workerRegistrar = WorkerRegistrar(
            workerConfigurations: workerConfigurations,
            workerAlivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults())
        
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
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
            statefulDequeueableBucketSource: bucketQueue,
            workerAlivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        )
        
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
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
        
        let resultHandler = BucketResultRegistrar(
            eventBus: EventBus(),
            statefulBucketResultAccepter: bucketQueue,
            workerAlivenessTracker: alivenessTracker
        )
        
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: resultHandler),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: stubbedEndpoint)
        )
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        _ = try client.send(testingResult: testingResult, requestId: requestId)
        
        XCTAssertEqual(bucketQueue.acceptedResults, [testingResult])
    }
    
    func test__ReportAliveHandler() throws {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: WorkerAlivenessEndpoint(alivenessTracker: alivenessTracker)),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
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
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: versionHandler)
        )
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)

        XCTAssertEqual(
            try client.fetchQueueServerVersion(),
            "abc"
        )
    }
    
    func test__schedule_tests() throws {
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntryFixtures.testEntry())
            .testEntryConfigurations()
        let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
        let testsEnqueuer = TestsEnqueuer(
            bucketSplitter: IndividualBucketSplitter(),
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: 0,
                toolResources: ToolResourcesFixtures.fakeToolResources(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings()
            ),
            enqueueableBucketReceptor: enqueueableBucketReceptor
        )
        let scheduleTestsEndpoint = ScheduleTestsEndpoint(testsEnqueuer: testsEnqueuer)
        
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            registerWorkerHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            reportAliveHandler: RESTEndpointOf(actualHandler: stubbedEndpoint),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: scheduleTestsEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: stubbedEndpoint)
        )
        let port = try restServer.start()
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        let acceptedRequestId = try client.scheduleTests(
            jobId: jobId,
            testEntryConfigurations: testEntryConfigurations,
            requestId: requestId
        )
        
        XCTAssertEqual(acceptedRequestId, requestId)
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[jobId],
            [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])]
        )
    }
}
