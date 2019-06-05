import AutomaticTermination
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
    let expectedRequestSignature = RequestSignature(value: "expectedRequestSignature")
    let restServer = QueueHTTPRESTServer(
        automaticTerminationController: AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: .stayAlive
        ).createAutomaticTerminationController(),
        localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange)
    )
    let workerConfigurations = WorkerConfigurations()
    let workerId = "worker"
    let requestId = "requestId"
    let jobId: JobId = "JobId"
    lazy var prioritizedJob = PrioritizedJob(jobId: jobId, priority: .medium)
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
        let bucket = BucketFixtures.createBucket(
            testEntries: [
                TestEntryFixtures.testEntry(className: "class1", methodName: "m1"),
                TestEntryFixtures.testEntry(className: "class2", methodName: "m2")
            ]
        )
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(bucket: bucket, enqueueTimestamp: Date()),
            workerId: workerId,
            requestId: requestId
        )
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: DequeueResult.dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedRequestSignature: expectedRequestSignature
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
            try client.fetchBucket(requestId: requestId, workerId: workerId, requestSignature: expectedRequestSignature),
            SynchronousQueueClient.BucketFetchResult.bucket(bucket)
        )
    }
    
    func test__ResultHandler() throws {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        let testingResult = TestingResultFixtures()
            .with(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "m1"))
            .addingLostResult()
            .with(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "m2"))
            .addingLostResult()
            .testingResult()
        
        let resultHandler = BucketResultRegistrar(
            bucketResultAccepter: bucketQueue,
            expectedRequestSignature: expectedRequestSignature,
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

        _ = try client.send(testingResult: testingResult, requestId: requestId, workerId: workerId, requestSignature: expectedRequestSignature)
        
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
            reportAliveHandler: RESTEndpointOf(
                actualHandler: WorkerAlivenessEndpoint(
                    alivenessTracker: alivenessTracker,
                    expectedRequestSignature: expectedRequestSignature
                )
            ),
            scheduleTestsHandler: stubbedHandler,
            versionHandler: stubbedHandler
        )
        let client = synchronousQueueClient(port: try restServer.start())
        
        try client.reportAliveness(bucketIdsBeingProcessedProvider: [], workerId: workerId, requestSignature: expectedRequestSignature)
        
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
            prioritizedJob: prioritizedJob,
            testEntryConfigurations: testEntryConfigurations,
            requestId: requestId
        )
        
        XCTAssertEqual(acceptedRequestId, requestId)
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[prioritizedJob],
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
