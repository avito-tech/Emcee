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
import RESTServer
import ScheduleStrategy
import Swifter
import SynchronousWaiter
import UniqueIdentifierGenerator
import Version
import WorkerAlivenessTracker

public final class QueueServerImpl: QueueServer {
    private let balancingBucketQueue: BalancingBucketQueue
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let jobResultsEndpoint: JobResultsEndpoint
    private let jobStateEndpoint: JobStateEndpoint
    private let jobDeleteEndpoint: JobDeleteEndpoint
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
        checkAgainTimeInterval: TimeInterval,
        localPortDeterminer: LocalPortDeterminer,
        workerAlivenessPolicy: WorkerAlivenessPolicy,
        bucketSplitInfo: BucketSplitInfo,
        queueServerLock: QueueServerLock,
        queueVersionProvider: VersionProvider,
        requestSignature: RequestSignature,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.workerAlivenessTracker = WorkerAlivenessTracker(
            dateProvider: dateProvider,
            reportAliveInterval: reportAliveInterval,
            additionalTimeToPerformWorkerIsAliveReport: 10.0
        )
        let balancingBucketQueueFactory = BalancingBucketQueueFactory(
            bucketQueueFactory: BucketQueueFactory(
                checkAgainTimeInterval: checkAgainTimeInterval,
                dateProvider: dateProvider,
                testHistoryTracker: TestHistoryTrackerImpl(
                    testHistoryStorage: TestHistoryStorageImpl(),
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator
                ),
                uniqueIdentifierGenerator: uniqueIdentifierGenerator,
                workerAlivenessProvider: workerAlivenessTracker
            ),
            nothingToDequeueBehavior: workerAlivenessPolicy.nothingToDequeueBehavior(
                checkLaterInterval: checkAgainTimeInterval
            )
        )
        self.balancingBucketQueue = balancingBucketQueueFactory.create()
        self.restServer = QueueHTTPRESTServer(
            httpRestServer: HTTPRESTServer(
                automaticTerminationController: automaticTerminationController,
                portProvider: localPortDeterminer
            )
        )
        self.testsEnqueuer = TestsEnqueuer(
            bucketSplitInfo: bucketSplitInfo,
            enqueueableBucketReceptor: balancingBucketQueue
        )
        self.scheduleTestsHandler = ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        self.workerAlivenessEndpoint = WorkerAlivenessEndpoint(
            workerAlivenessProvider: workerAlivenessTracker,
            expectedRequestSignature: requestSignature
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
            expectedRequestSignature: requestSignature
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            bucketResultAccepter: BucketResultAccepterWithMetricSupport(
                bucketResultAccepter: balancingBucketQueue,
                eventBus: eventBus,
                jobStateProvider: balancingBucketQueue,
                queueStateProvider: balancingBucketQueue
            ),
            expectedRequestSignature: requestSignature,
            workerAlivenessTracker: workerAlivenessTracker
        )
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
    
    public func schedule(
        bucketSplitter: BucketSplitter,
        testEntryConfigurations: [TestEntryConfiguration],
        prioritizedJob: PrioritizedJob
    ) {
        testsEnqueuer.enqueue(
            bucketSplitter: bucketSplitter,
            testEntryConfigurations: testEntryConfigurations,
            prioritizedJob: prioritizedJob
        )
    }
    
    public var isDepleted: Bool {
        return balancingBucketQueue.runningQueueState.isDepleted
    }
    
    public var hasAnyAliveWorker: Bool {
        return workerAlivenessTracker.hasAnyAliveWorker
    }
    
    public var ongoingJobIds: Set<JobId> {
        return balancingBucketQueue.ongoingJobIds
    }
    
    public func queueResults(jobId: JobId) throws -> JobResults {
        return try balancingBucketQueue.results(jobId: jobId)
    }
}
