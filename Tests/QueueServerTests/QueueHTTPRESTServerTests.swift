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
    let jobId: JobId = "JobId"
    let stubbedHandler = RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int, Int>(0))
    
    override func setUp() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    func test__RegisterWorkerHandler() throws {
        let workerRegistrar = WorkerRegistrar(
            workerConfigurations: workerConfigurations,
            workerAlivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults())
        
        restServer.setHandler(
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        
        XCTAssertEqual(
            try client.registerWithServer(workerId: workerId),
            WorkerConfigurationFixtures.workerConfiguration
        )
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
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        
        XCTAssertEqual(
            try client.fetchBucket(requestId: requestId, workerId: workerId),
            SynchronousQueueClient.BucketFetchResult.bucket(bucket)
        )
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
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())

        _ = try client.send(testingResult: testingResult, requestId: requestId, workerId: workerId)
        
        XCTAssertEqual(bucketQueue.acceptedResults, [testingResult])
    }
    
    func test__ReportAliveHandler() throws {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        
        restServer.setHandler(
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: RESTEndpointOf(actualHandler: WorkerAlivenessEndpoint(alivenessTracker: alivenessTracker)),
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        
        try client.reportAliveness(bucketIdsBeingProcessedProvider: { [] }, workerId: workerId)
        
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId).status, .alive)
    }
    
    func test__QueueServerVersion() throws {
        let versionHandler = FakeRESTEndpoint<QueueVersionRequest, QueueVersionResponse>(QueueVersionResponse.queueVersion("abc"))
        
        restServer.setHandler(
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: RESTEndpointOf(actualHandler: versionHandler)
        )
        let client = synchronousQueueClient(port: try restServer.start())

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
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: RESTEndpointOf(actualHandler: scheduleTestsEndpoint),
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        
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
    
    func test___job_state() throws {
        let jobState = JobState(
            jobId: jobId,
            queueState: QueueState(
                enqueuedBucketCount: 24,
                dequeuedBucketCount: 42
            )
        )
        let jobStateHandler = FakeRESTEndpoint<JobStateRequest, JobStateResponse>(JobStateResponse(jobState: jobState))
        
        restServer.setHandler(
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: stubbedHandler,
            jobStateHandler: RESTEndpointOf(actualHandler: jobStateHandler),
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        
        XCTAssertEqual(
            try client.jobState(jobId: jobId),
            jobState
        )
    }
    
    func test___job_results() throws {
        let jobResults = JobResults(jobId: jobId, testingResults: [])
        let jobResultsHandler = FakeRESTEndpoint<JobResultsRequest, JobResultsResponse>(
            JobResultsResponse(jobResults: jobResults)
        )
        
        restServer.setHandler(
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: stubbedHandler,
            jobResultsHandler: RESTEndpointOf(actualHandler: jobResultsHandler),
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        XCTAssertEqual(
            try client.jobResults(jobId: jobId),
            jobResults
        )
    }
    
    func test___deleting_job() throws {
        let jobResultsHandler = FakeRESTEndpoint<JobDeleteRequest, JobDeleteResponse>(
            JobDeleteResponse(jobId: jobId)
        )
        
        restServer.setHandler(
            bucketResultHandler: stubbedHandler,
            dequeueBucketRequestHandler: stubbedHandler,
            jobDeleteHandler: RESTEndpointOf(actualHandler: jobResultsHandler),
            jobResultsHandler: stubbedHandler,
            jobStateHandler: stubbedHandler,
            registerWorkerHandler: stubbedHandler,
            reportAliveHandler: stubbedHandler,
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        XCTAssertEqual(
            try client.delete(jobId: jobId),
            jobId
        )
    }
    
    private func synchronousQueueClient(port: Int) -> SynchronousQueueClient {
        return SynchronousQueueClient(queueServerAddress: SocketAddress(host: "localhost", port: port))
    }
}
