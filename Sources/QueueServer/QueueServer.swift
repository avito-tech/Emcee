import BalancingBucketQueue
import BucketQueue
import EventBus
import Extensions
import Foundation
import Logging
import Models
import PortDeterminer
import RESTMethods
import ResultsCollector
import ScheduleStrategy
import Swifter
import SynchronousWaiter
import Version
import WorkerAlivenessTracker

public final class QueueServer {
    private let balancingBucketQueue: BalancingBucketQueue
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let queueExhaustTimeAllowance: TimeInterval
    private let queueServerVersionHandler: QueueServerVersionEndpoint
    private let restServer: QueueHTTPRESTServer
    private let resultsCollector = ResultsCollector()
    private let scheduleTestsHandler: ScheduleTestsEndpoint
    private let stuckBucketsPoller: StuckBucketsPoller
    private let testsEnqueuer: TestsEnqueuer
    private let workerAlivenessEndpoint: WorkerAlivenessEndpoint
    private let workerAlivenessTracker: WorkerAlivenessTracker
    private let workerRegistrar: WorkerRegistrar
    
    public init(
        eventBus: EventBus,
        workerConfigurations: WorkerConfigurations,
        reportAliveInterval: TimeInterval,
        numberOfRetries: UInt,
        newWorkerRegistrationTimeAllowance: TimeInterval = 60.0,
        queueExhaustTimeAllowance: TimeInterval = .infinity,
        checkAgainTimeInterval: TimeInterval,
        localPortDeterminer: LocalPortDeterminer,
        nothingToDequeueBehavior: NothingToDequeueBehavior,
        bucketSplitter: BucketSplitter,
        bucketSplitInfo: BucketSplitInfo,
        queueVersionProvider: VersionProvider)
    {
        self.workerAlivenessTracker = WorkerAlivenessTracker(
            reportAliveInterval: reportAliveInterval,
            additionalTimeToPerformWorkerIsAliveReport: 10.0
        )
        
        let balancingBucketQueueFactory = BalancingBucketQueueFactory(
            bucketQueueFactory: BucketQueueFactory(
                workerAlivenessProvider: workerAlivenessTracker,
                testHistoryTracker: TestHistoryTrackerImpl(
                    numberOfRetries: numberOfRetries,
                    testHistoryStorage: TestHistoryStorageImpl()
                ),
                checkAgainTimeInterval: checkAgainTimeInterval
            ),
            nothingToDequeueBehavior: nothingToDequeueBehavior
        )
        self.balancingBucketQueue = balancingBucketQueueFactory.create()
        
        self.restServer = QueueHTTPRESTServer(localPortDeterminer: localPortDeterminer)
        
        self.testsEnqueuer = TestsEnqueuer(
            bucketSplitter: bucketSplitter,
            bucketSplitInfo: bucketSplitInfo,
            enqueueableBucketReceptor: balancingBucketQueue
        )
        self.scheduleTestsHandler = ScheduleTestsEndpoint(testsEnqueuer: testsEnqueuer)
        
        self.workerAlivenessEndpoint = WorkerAlivenessEndpoint(
            alivenessTracker: workerAlivenessTracker
        )
        self.workerRegistrar = WorkerRegistrar(
            workerConfigurations: workerConfigurations,
            workerAlivenessTracker: workerAlivenessTracker
        )
        self.stuckBucketsPoller = StuckBucketsPoller(
            statefulStuckBucketsReenqueuer: balancingBucketQueue
        )
        self.bucketProvider = BucketProviderEndpoint(
            statefulDequeueableBucketSource: balancingBucketQueue,
            workerAlivenessTracker: workerAlivenessTracker
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            eventBus: eventBus,
            resultsCollector: resultsCollector,
            statefulBucketResultAccepter: balancingBucketQueue,
            workerAlivenessTracker: workerAlivenessTracker
        )
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.queueExhaustTimeAllowance = queueExhaustTimeAllowance
        self.queueServerVersionHandler = QueueServerVersionEndpoint(versionProvider: queueVersionProvider)
    }
    
    public func start() throws -> Int {
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: bucketResultRegistrar),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            reportAliveHandler: RESTEndpointOf(actualHandler: workerAlivenessEndpoint),
            scheduleTestsHandler: RESTEndpointOf(actualHandler: scheduleTestsHandler),
            versionHandler: RESTEndpointOf(actualHandler: queueServerVersionHandler)
        )
        
        stuckBucketsPoller.startTrackingStuckBuckets()
        
        let port = try restServer.start()
        Logger.info("Started queue server on port \(port)")
        return port
    }
    
    public func schedule(testEntryConfigurations: [TestEntryConfiguration], jobId: JobId) {
        testsEnqueuer.enqueue(testEntryConfigurations: testEntryConfigurations, jobId: jobId)
    }
    
    public func waitForJobToFinish(jobId: JobId) throws -> [TestingResult] {
        Logger.debug("Waiting for workers to appear")
        try SynchronousWaiter.waitWhile(pollPeriod: 1, timeout: newWorkerRegistrationTimeAllowance, description: "Waiting workers to appear") {
            workerAlivenessTracker.hasAnyAliveWorker == false
        }
        
        Logger.debug("Waiting for bucket queue to deplete")
        try SynchronousWaiter.waitWhile(pollPeriod: 5, timeout: queueExhaustTimeAllowance, description: "Waiting for queue to exhaust") {
            guard workerAlivenessTracker.hasAnyAliveWorker else { throw QueueServerError.noWorkers }
            return !balancingBucketQueue.state.isDepleted
        }
        Logger.debug("Bucket queue has depleted")
        return resultsCollector.collectedResults
    }
}
