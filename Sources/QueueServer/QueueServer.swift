import AutomaticTermination
import BalancingBucketQueue
import BucketQueue
import DateProvider
import EventBus
import Extensions
import Foundation
import Logging
import Models
import PortDeterminer
import RESTMethods
import ScheduleStrategy
import Swifter
import SynchronousWaiter
import Version
import WorkerAlivenessTracker

public final class QueueServer {
    private let balancingBucketQueue: BalancingBucketQueue
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let jobResultsEndpoint: JobResultsEndpoint
    private let jobStateEndpoint: JobStateEndpoint
    private let jobDeleteEndpoint: JobDeleteEndpoint
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let queueExhaustTimeAllowance: TimeInterval
    private let queueServerVersionHandler: QueueServerVersionEndpoint
    private let restServer: QueueHTTPRESTServer
    private let scheduleTestsHandler: ScheduleTestsEndpoint
    private let stuckBucketsPoller: StuckBucketsPoller
    private let testsEnqueuer: TestsEnqueuer
    private let workerAlivenessEndpoint: WorkerAlivenessEndpoint
    private let workerAlivenessTracker: WorkerAlivenessTracker
    private let workerRegistrar: WorkerRegistrar
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        dateProvider: DateProvider,
        eventBus: EventBus,
        workerConfigurations: WorkerConfigurations,
        reportAliveInterval: TimeInterval,
        newWorkerRegistrationTimeAllowance: TimeInterval,
        queueExhaustTimeAllowance: TimeInterval = .infinity,
        checkAgainTimeInterval: TimeInterval,
        localPortDeterminer: LocalPortDeterminer,
        workerAlivenessPolicy: WorkerAlivenessPolicy,
        bucketSplitter: BucketSplitter,
        bucketSplitInfo: BucketSplitInfo,
        queueServerLock: QueueServerLock,
        queueVersionProvider: VersionProvider)
    {
        self.workerAlivenessTracker = WorkerAlivenessTracker(
            reportAliveInterval: reportAliveInterval,
            additionalTimeToPerformWorkerIsAliveReport: 10.0
        )
        let balancingBucketQueueFactory = BalancingBucketQueueFactory(
            bucketQueueFactory: BucketQueueFactory(
                checkAgainTimeInterval: checkAgainTimeInterval,
                dateProvider: dateProvider,
                testHistoryTracker: TestHistoryTrackerImpl(
                    testHistoryStorage: TestHistoryStorageImpl()
                ),
                workerAlivenessProvider: workerAlivenessTracker
            ),
            nothingToDequeueBehavior: workerAlivenessPolicy.nothingToDequeueBehavior(
                checkLaterInterval: checkAgainTimeInterval
            )
        )
        self.balancingBucketQueue = balancingBucketQueueFactory.create()
        self.restServer = QueueHTTPRESTServer(
            automaticTerminationController: automaticTerminationController,
            localPortDeterminer: localPortDeterminer
        )
        self.testsEnqueuer = TestsEnqueuer(
            bucketSplitter: bucketSplitter,
            bucketSplitInfo: bucketSplitInfo,
            enqueueableBucketReceptor: balancingBucketQueue
        )
        self.scheduleTestsHandler = ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer
        )
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
            dequeueableBucketSource: DequeueableBucketSourceWithMetricSupport(
                dequeueableBucketSource: balancingBucketQueue,
                jobStateProvider: balancingBucketQueue,
                queueStateProvider: balancingBucketQueue
            ),
            workerAlivenessTracker: workerAlivenessTracker
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            bucketResultAccepter: BucketResultAccepterWithMetricSupport(
                bucketResultAccepter: balancingBucketQueue,
                eventBus: eventBus,
                jobStateProvider: balancingBucketQueue,
                queueStateProvider: balancingBucketQueue
            ),
            workerAlivenessTracker: workerAlivenessTracker
        )
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.queueExhaustTimeAllowance = queueExhaustTimeAllowance
        self.queueServerVersionHandler = QueueServerVersionEndpoint(
            queueServerLock: queueServerLock,
            versionProvider: queueVersionProvider
        )
        self.jobResultsEndpoint = JobResultsEndpoint(
            jobResultsProvider: balancingBucketQueue
        )
        self.jobStateEndpoint = JobStateEndpoint(
            stateProvider: balancingBucketQueue
        )
        self.jobDeleteEndpoint = JobDeleteEndpoint(
            jobManipulator: balancingBucketQueue
        )
    }
    
    public func start() throws -> Int {
        restServer.setHandler(
            bucketResultHandler: RESTEndpointOf(actualHandler: bucketResultRegistrar),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            jobDeleteHandler: RESTEndpointOf(actualHandler: jobDeleteEndpoint),
            jobResultsHandler: RESTEndpointOf(actualHandler: jobResultsEndpoint),
            jobStateHandler: RESTEndpointOf(actualHandler: jobStateEndpoint),
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
    
    public func schedule(testEntryConfigurations: [TestEntryConfiguration], prioritizedJob: PrioritizedJob) {
        testsEnqueuer.enqueue(
            testEntryConfigurations: testEntryConfigurations,
            prioritizedJob: prioritizedJob
        )
    }
    
    public func waitForWorkersToAppear() throws {
        if !workerAlivenessTracker.hasAnyAliveWorker {
            Logger.debug("Waiting for workers to appear")
            try SynchronousWaiter.waitWhile(pollPeriod: 1, timeout: newWorkerRegistrationTimeAllowance, description: "Waiting workers to appear") {
                workerAlivenessTracker.hasAnyAliveWorker == false
            }
        }
    }
    
    public func waitForBalancingQueueToDeplete() throws {
        if !balancingBucketQueue.state.isDepleted {
            Logger.debug("Waiting for bucket queue to deplete with timeout: \(queueExhaustTimeAllowance)")
            try SynchronousWaiter.waitWhile(pollPeriod: 5, timeout: queueExhaustTimeAllowance, description: "Waiting for queue to exhaust") {
                guard workerAlivenessTracker.hasAnyAliveWorker else { throw QueueServerError.noWorkers }
                return !balancingBucketQueue.state.isDepleted
            }
        }
    }
    
    public var ongoingJobIds: Set<JobId> {
        return balancingBucketQueue.ongoingJobIds
    }
    
    public func waitForJobToFinish(jobId: JobId) throws -> JobResults {
        try waitForWorkersToAppear()
        try waitForBalancingQueueToDeplete()

        Logger.debug("Bucket queue has depleted")
        return try balancingBucketQueue.results(jobId: jobId)
    }
}
