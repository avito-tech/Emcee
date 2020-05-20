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
import RESTInterfaces
import RESTMethods
import RESTServer
import RequestSender
import ScheduleStrategy
import Swifter
import SynchronousWaiter
import UniqueIdentifierGenerator
import WorkerAlivenessProvider

public final class QueueServerImpl: QueueServer {
    private let balancingBucketQueue: BalancingBucketQueue
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let disableWorkerHandler: DisableWorkerEndpoint
    private let enableWorkerHandler: EnableWorkerEndpoint
    private let httpRestServer: HTTPRESTServer
    private let jobDeleteEndpoint: JobDeleteEndpoint
    private let jobResultsEndpoint: JobResultsEndpoint
    private let jobStateEndpoint: JobStateEndpoint
    private let queueServerVersionHandler: QueueServerVersionEndpoint
    private let scheduleTestsHandler: ScheduleTestsEndpoint
    private let stuckBucketsPoller: StuckBucketsPoller
    private let testsEnqueuer: TestsEnqueuer
    private let workerAlivenessMatricCapturer: WorkerAlivenessMatricCapturer
    private let workerAlivenessPoller: WorkerAlivenessPoller
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerRegistrar: WorkerRegistrar
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        bucketSplitInfo: BucketSplitInfo,
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        emceeVersion: Version,
        localPortDeterminer: LocalPortDeterminer,
        payloadSignature: PayloadSignature,
        queueServerLock: QueueServerLock,
        requestSenderProvider: RequestSenderProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessPolicy: WorkerAlivenessPolicy,
        workerConfigurations: WorkerConfigurations
    ) {
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: automaticTerminationController,
            portProvider: localPortDeterminer
        )
        
        let alivenessPollingInterval: TimeInterval = 20
        let workerDetailsHolder = WorkerDetailsHolderImpl()
        
        self.workerAlivenessProvider = WorkerAlivenessProviderImpl(
            dateProvider: dateProvider,
            knownWorkerIds: workerConfigurations.workerIds,
            maximumNotReportingDuration: alivenessPollingInterval * 2 + 10
        )
        self.workerAlivenessPoller = WorkerAlivenessPoller(
            pollInterval: alivenessPollingInterval,
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
        self.testsEnqueuer = TestsEnqueuer(
            bucketSplitInfo: bucketSplitInfo,
            enqueueableBucketReceptor: balancingBucketQueue
        )
        self.scheduleTestsHandler = ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
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
        self.disableWorkerHandler = DisableWorkerEndpoint(
            workerAlivenessProvider: workerAlivenessProvider,
            workerConfigurations: workerConfigurations
        )
        self.enableWorkerHandler = EnableWorkerEndpoint(
            workerAlivenessProvider: workerAlivenessProvider,
            workerConfigurations: workerConfigurations
        )
        self.queueServerVersionHandler = QueueServerVersionEndpoint(
            emceeVersion: emceeVersion,
            queueServerLock: queueServerLock
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
        httpRestServer.add(handler: RESTEndpointOf(bucketProvider))
        httpRestServer.add(handler: RESTEndpointOf(bucketResultRegistrar))
        httpRestServer.add(handler: RESTEndpointOf(disableWorkerHandler))
        httpRestServer.add(handler: RESTEndpointOf(enableWorkerHandler))
        httpRestServer.add(handler: RESTEndpointOf(jobDeleteEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(jobResultsEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(jobStateEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(queueServerVersionHandler))
        httpRestServer.add(handler: RESTEndpointOf(scheduleTestsHandler))
        httpRestServer.add(handler: RESTEndpointOf(workerRegistrar))

        stuckBucketsPoller.startTrackingStuckBuckets()
        workerAlivenessMatricCapturer.start()
        workerAlivenessPoller.startPolling()
        
        let port = try httpRestServer.start()
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
