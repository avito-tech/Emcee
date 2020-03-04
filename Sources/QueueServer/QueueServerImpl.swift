import AutomaticTermination
import BalancingBucketQueue
import BucketQueue
import DateProvider
import DistWorkerModels
import Extensions
import Foundation
import Logging
import Models
import PortDeterminer
import QueueModels
import RESTMethods
import RESTServer
import RequestSender
import ScheduleStrategy
import Swifter
import SynchronousWaiter
import UniqueIdentifierGenerator
import Version
import WorkerAlivenessProvider

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
    private let workerAlivenessMatricCapturer: WorkerAlivenessMatricCapturer
    private let workerAlivenessPoller: WorkerAlivenessPoller
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerRegistrar: WorkerRegistrar
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        bucketSplitInfo: BucketSplitInfo,
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        localPortDeterminer: LocalPortDeterminer,
        payloadSignature: PayloadSignature,
        queueServerLock: QueueServerLock,
        queueVersionProvider: VersionProvider,
        reportAliveInterval: TimeInterval,
        requestSenderProvider: RequestSenderProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessPolicy: WorkerAlivenessPolicy,
        workerConfigurations: WorkerConfigurations
    ) {
        let workerDetailsHolder = WorkerDetailsHolderImpl()
        
        self.workerAlivenessProvider = WorkerAlivenessProviderImpl(
            dateProvider: dateProvider,
            reportAliveInterval: reportAliveInterval,
            additionalTimeToPerformWorkerIsAliveReport: 30.0
        )
        self.workerAlivenessPoller = WorkerAlivenessPoller(
            pollInterval: 20,
            requestSenderProvider: requestSenderProvider,
            workerAlivenessProvider: workerAlivenessProvider,
            workerDetailsHolder: workerDetailsHolder
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
                workerAlivenessProvider: workerAlivenessProvider
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
            workerAlivenessProvider: workerAlivenessProvider,
            expectedPayloadSignature: payloadSignature
        )
        self.workerRegistrar = WorkerRegistrar(
            workerAlivenessProvider: workerAlivenessProvider,
            workerConfigurations: workerConfigurations,
            workerDetailsHolder: workerDetailsHolder
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
            expectedPayloadSignature: payloadSignature
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            bucketResultAccepter: BucketResultAccepterWithMetricSupport(
                bucketResultAccepter: balancingBucketQueue,
                jobStateProvider: balancingBucketQueue,
                queueStateProvider: balancingBucketQueue
            ),
            expectedPayloadSignature: payloadSignature,
            workerAlivenessProvider: workerAlivenessProvider
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
        self.workerAlivenessMatricCapturer = WorkerAlivenessMatricCapturer(
            reportInterval: .seconds(30),
            workerAlivenessProvider: workerAlivenessProvider
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
        workerAlivenessMatricCapturer.start()
        workerAlivenessPoller.startPolling()
        
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
        return workerAlivenessProvider.hasAnyAliveWorker
    }
    
    public var ongoingJobIds: Set<JobId> {
        return balancingBucketQueue.ongoingJobIds
    }
    
    public func queueResults(jobId: JobId) throws -> JobResults {
        return try balancingBucketQueue.results(jobId: jobId)
    }
}
