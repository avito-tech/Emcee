import AutomaticTermination
import BalancingBucketQueue
import BucketQueue
import DateProvider
import Deployer
import DistWorkerModels
import Foundation
import EmceeLogging
import Metrics
import MetricsExtensions
import PortDeterminer
import QueueCommunication
import QueueModels
import QueueServerPortProvider
import RESTInterfaces
import RESTMethods
import RESTServer
import RequestSender
import ScheduleStrategy
import SocketModels
import Swifter
import SynchronousWaiter
import TestHistoryStorage
import TestHistoryTracker
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities

public final class QueueServerImpl: QueueServer {
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let disableWorkerHandler: DisableWorkerEndpoint
    private let enableWorkerHandler: EnableWorkerEndpoint
    private let httpRestServer: HTTPRESTServer
    private let jobDeleteEndpoint: JobDeleteEndpoint
    private let jobResultsEndpoint: JobResultsEndpoint
    private let jobResultsProvider: JobResultsProvider
    private let jobStateEndpoint: JobStateEndpoint
    private let jobStateProvider: JobStateProvider
    private let kickstartWorkerEndpoint: KickstartWorkerEndpoint
    private let logger: ContextualLogger
    private let queueServerVersionHandler: QueueServerVersionEndpoint
    private let scheduleTestsHandler: ScheduleTestsEndpoint
    private let statefulBucketQueue: StatefulBucketQueue
    private let stuckBucketsPoller: StuckBucketsPoller
    private let testsEnqueuer: TestsEnqueuer
    private let toggleWorkersSharingEndpoint: ToggleWorkersSharingEndpoint
    private let workerAlivenessMetricCapturer: WorkerAlivenessMetricCapturer
    private let workerAlivenessPoller: WorkerAlivenessPoller
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerIdsEndpoint: WorkerIdsEndpoint
    private let workerRegistrar: WorkerRegistrar
    private let workerStatusEndpoint: WorkerStatusEndpoint
    private let workersToUtilizeEndpoint: WorkersToUtilizeEndpoint
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        autoupdatingWorkerPermissionProvider: AutoupdatingWorkerPermissionProvider,
        bucketGenerator: BucketGenerator,
        bucketSplitInfo: BucketSplitInfo,
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        emceeVersion: Version,
        localPortDeterminer: LocalPortDeterminer,
        logger: ContextualLogger,
        globalMetricRecorder: GlobalMetricRecorder,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider,
        onDemandWorkerStarter: OnDemandWorkerStarter,
        payloadSignature: PayloadSignature,
        queueServerLock: QueueServerLock,
        requestSenderProvider: RequestSenderProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage,
        workerConfigurations: WorkerConfigurations,
        workerIds: Set<WorkerId>,
        workersToUtilizeService: WorkersToUtilizeService
    ) {
        self.logger = logger
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: automaticTerminationController,
            logger: logger,
            portProvider: localPortDeterminer
        )
        
        let alivenessPollingInterval: TimeInterval = 20
        let workerDetailsHolder = WorkerDetailsHolderImpl()
        
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerAlivenessPoller = WorkerAlivenessPoller(
            logger: logger,
            pollInterval: alivenessPollingInterval,
            requestSenderProvider: requestSenderProvider,
            workerAlivenessProvider: workerAlivenessProvider,
            workerDetailsHolder: workerDetailsHolder
        )
        
        let multipleQueuesContainer = MultipleQueuesContainer()
        let jobManipulator: JobManipulator = MultipleQueuesJobManipulator(
            dateProvider: dateProvider,
            specificMetricRecorderProvider: specificMetricRecorderProvider,
            multipleQueuesContainer: multipleQueuesContainer,
            emceeVersion: emceeVersion
        )
        let singleStatefulBucketQueueProvider = SingleStatefulBucketQueueProvider()
        let singleEmptyableBucketQueueProvider = SingleEmptyableBucketQueueProvider()
        
        self.jobStateProvider = MultipleQueuesJobStateProvider(
            multipleQueuesContainer: multipleQueuesContainer,
            statefulBucketQueueProvider: singleStatefulBucketQueueProvider
        )
        self.jobResultsProvider = MultipleQueuesJobResultsProvider(
            multipleQueuesContainer: multipleQueuesContainer
        )
        
        let testHistoryTracker: TestHistoryTracker = TestHistoryTrackerImpl(
            testHistoryStorage: TestHistoryStorageImpl(),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        
        let singleBucketQueueEnqueuerProvider = SingleBucketQueueEnqueuerProvider(
            dateProvider: dateProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
        let enqueueableBucketReceptor: EnqueueableBucketReceptor = MultipleQueuesEnqueueableBucketReceptor(
            bucketEnqueuerProvider: singleBucketQueueEnqueuerProvider,
            emptyableBucketQueueProvider: singleEmptyableBucketQueueProvider,
            multipleQueuesContainer: multipleQueuesContainer
        )
        let testingResultAcceptorProvider = TestingResultAcceptorProviderImpl(
            bucketEnqueuerProvider: singleBucketQueueEnqueuerProvider,
            logger: logger,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        self.statefulBucketQueue = MultipleQueuesStatefulBucketQueue(
            multipleQueuesContainer: multipleQueuesContainer,
            statefulBucketQueueProvider: singleStatefulBucketQueueProvider
        )
        
        let dequeueableBucketSource: DequeueableBucketSource = DequeueableBucketSourceWithMetricSupport(
            dateProvider: dateProvider,
            dequeueableBucketSource: WorkerPermissionAwareDequeueableBucketSource(
                dequeueableBucketSource: MultipleQueuesDequeueableBucketSource(
                    dequeueableBucketSourceProvider: SingleBucketQueueDequeueableBucketSourceProvider(
                        logger: logger,
                        testHistoryTracker: testHistoryTracker,
                        workerAlivenessProvider: workerAlivenessProvider,
                        workerCapabilitiesStorage: workerCapabilitiesStorage,
                        workerCapabilityConstraintResolver: WorkerCapabilityConstraintResolver()
                    ),
                    multipleQueuesContainer: multipleQueuesContainer
                ),
                workerPermissionProvider: autoupdatingWorkerPermissionProvider
            ),
            jobStateProvider: jobStateProvider,
            logger: logger,
            statefulBucketQueue: statefulBucketQueue,
            specificMetricRecorderProvider: specificMetricRecorderProvider,
            version: emceeVersion
        )
        let bucketResultAcceptor: BucketResultAcceptor = MultipleQueuesBucketResultAcceptor(
            bucketResultAcceptorProvider: SingleBucketResultAcceptorProvider(
                logger: logger,
                testingResultAcceptorProvider: testingResultAcceptorProvider
            ),
            multipleQueuesContainer: multipleQueuesContainer
        )
        let stuckBucketsReenqueuer: StuckBucketsReenqueuer = MultipleQueuesStuckBucketsReenqueuer(
            multipleQueuesContainer: multipleQueuesContainer,
            stuckBucketsReenqueuerProvider: SingleBucketQueueStuckBucketsReenqueuerProvider(
                logger: logger,
                bucketEnqueuerProvider: singleBucketQueueEnqueuerProvider,
                workerAlivenessProvider: workerAlivenessProvider,
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            )
        )
        
        self.testsEnqueuer = TestsEnqueuer(
            bucketGenerator: bucketGenerator,
            bucketSplitInfo: bucketSplitInfo,
            dateProvider: dateProvider,
            enqueueableBucketReceptor: enqueueableBucketReceptor,
            logger: logger,
            version: emceeVersion,
            specificMetricRecorderProvider: specificMetricRecorderProvider
        )
        self.scheduleTestsHandler = ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            waitForCapableWorkerTimeout: alivenessPollingInterval * 2,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
        self.workerRegistrar = WorkerRegistrar(
            logger: logger,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage,
            workerConfigurations: workerConfigurations,
            workerDetailsHolder: workerDetailsHolder
        )
        self.stuckBucketsPoller = StuckBucketsPoller(
            dateProvider: dateProvider,
            globalMetricRecorder: globalMetricRecorder,
            jobStateProvider: jobStateProvider,
            logger: logger,
            specificMetricRecorderProvider: specificMetricRecorderProvider,
            statefulBucketQueue: statefulBucketQueue,
            stuckBucketsReenqueuer: stuckBucketsReenqueuer,
            version: emceeVersion
        )
        self.bucketProvider = BucketProviderEndpoint(
            checkAfter: checkAgainTimeInterval,
            dequeueableBucketSource: dequeueableBucketSource,
            expectedPayloadSignature: payloadSignature,
            workerAlivenessProvider: workerAlivenessProvider
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            bucketResultAcceptor: BucketResultAcceptorWithMetricSupport(
                bucketResultAcceptor: bucketResultAcceptor,
                dateProvider: dateProvider,
                jobStateProvider: jobStateProvider,
                logger: logger,
                specificMetricRecorderProvider: specificMetricRecorderProvider,
                statefulBucketQueue: statefulBucketQueue,
                version: emceeVersion
            ),
            expectedPayloadSignature: payloadSignature
        )
        self.kickstartWorkerEndpoint = KickstartWorkerEndpoint(
            onDemandWorkerStarter: onDemandWorkerStarter,
            workerAlivenessProvider: workerAlivenessProvider,
            workerConfigurations: workerConfigurations
        )
        self.disableWorkerHandler = DisableWorkerEndpoint(
            workerAlivenessProvider: workerAlivenessProvider,
            workerConfigurations: workerConfigurations
        )
        self.enableWorkerHandler = EnableWorkerEndpoint(
            workerAlivenessProvider: workerAlivenessProvider,
            workerConfigurations: workerConfigurations
        )
        self.workerStatusEndpoint = WorkerStatusEndpoint(
            workerAlivenessProvider: workerAlivenessProvider
        )
        self.queueServerVersionHandler = QueueServerVersionEndpoint(
            emceeVersion: emceeVersion,
            queueServerLock: queueServerLock
        )
        self.jobResultsEndpoint = JobResultsEndpoint(
            jobResultsProvider: jobResultsProvider
        )
        self.jobStateEndpoint = JobStateEndpoint(
            stateProvider: jobStateProvider
        )
        self.jobDeleteEndpoint = JobDeleteEndpoint(
            jobManipulator: jobManipulator
        )
        self.workerAlivenessMetricCapturer = WorkerAlivenessMetricCapturer(
            dateProvider: dateProvider,
            reportInterval: .seconds(30),
            version: emceeVersion,
            workerAlivenessProvider: workerAlivenessProvider,
            globalMetricRecorder: globalMetricRecorder
        )
        self.workersToUtilizeEndpoint = WorkersToUtilizeEndpoint(
            logger: logger, 
            service: workersToUtilizeService
        )
        self.workerIdsEndpoint = WorkerIdsEndpoint(
            workerIds: workerIds
        )
        self.toggleWorkersSharingEndpoint = ToggleWorkersSharingEndpoint(
            autoupdatingWorkerPermissionProvider: autoupdatingWorkerPermissionProvider
        )
    }
    
    public func start() throws -> SocketModels.Port {
        httpRestServer.add(handler: RESTEndpointOf(bucketProvider))
        httpRestServer.add(handler: RESTEndpointOf(bucketResultRegistrar))
        httpRestServer.add(handler: RESTEndpointOf(disableWorkerHandler))
        httpRestServer.add(handler: RESTEndpointOf(enableWorkerHandler))
        httpRestServer.add(handler: RESTEndpointOf(jobDeleteEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(jobResultsEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(jobStateEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(kickstartWorkerEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(queueServerVersionHandler))
        httpRestServer.add(handler: RESTEndpointOf(scheduleTestsHandler))
        httpRestServer.add(handler: RESTEndpointOf(toggleWorkersSharingEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(workerIdsEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(workerRegistrar))
        httpRestServer.add(handler: RESTEndpointOf(workerStatusEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(workersToUtilizeEndpoint))

        stuckBucketsPoller.startTrackingStuckBuckets()
        workerAlivenessMetricCapturer.start()
        workerAlivenessPoller.startPolling()
        
        let port = try httpRestServer.start()
        logger.info("Started queue server on port \(port)")
        
        return port
    }
    
    public func schedule(
        testEntryConfigurations: [TestEntryConfiguration],
        testSplitter: TestSplitter,
        prioritizedJob: PrioritizedJob
    ) throws {
        try testsEnqueuer.enqueue(
            testEntryConfigurations: testEntryConfigurations,
            testSplitter: testSplitter,
            prioritizedJob: prioritizedJob
        )
    }
    
    public var isDepleted: Bool {
        return statefulBucketQueue.runningQueueState.isDepleted
    }
    
    public var hasAnyAliveWorker: Bool {
        return workerAlivenessProvider.hasAnyAliveWorker
    }
    
    public var ongoingJobIds: Set<JobId> {
        return jobStateProvider.ongoingJobIds
    }
    
    public func queueResults(jobId: JobId) throws -> JobResults {
        return try jobResultsProvider.results(jobId: jobId)
    }
    
    public var queueServerPortProvider: QueueServerPortProvider {
        httpRestServer
    }
}

extension HTTPRESTServer: QueueServerPortProvider {}
