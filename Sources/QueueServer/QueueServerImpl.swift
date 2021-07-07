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
    private let deploymentDestinationsHandler: DeploymentDestinationsEndpoint
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
    private let runningQueueStateProvider: RunningQueueStateProvider
    private let scheduleTestsHandler: ScheduleTestsEndpoint
    private let stuckBucketsPoller: StuckBucketsPoller
    private let testsEnqueuer: TestsEnqueuer
    private let toggleWorkersSharingEndpoint: ToggleWorkersSharingEndpoint
    private let workerAlivenessMetricCapturer: WorkerAlivenessMetricCapturer
    private let workerAlivenessPoller: WorkerAlivenessPoller
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerRegistrar: WorkerRegistrar
    private let workerStatusEndpoint: WorkerStatusEndpoint
    private let workersToUtilizeEndpoint: WorkersToUtilizeEndpoint
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        bucketSplitInfo: BucketSplitInfo,
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        deploymentDestinations: [DeploymentDestination],
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
        workerUtilizationStatusPoller: WorkerUtilizationStatusPoller,
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
        
        let bucketQueueFactory = BucketQueueFactoryImpl(
            dateProvider: dateProvider,
            logger: logger,
            testHistoryTracker: TestHistoryTrackerImpl(
                testHistoryStorage: TestHistoryStorageImpl(),
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            ),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
        
        let multipleQueuesContainer = MultipleQueuesContainer()
        let jobManipulator: JobManipulator = MultipleQueuesJobManipulator(
            dateProvider: dateProvider,
            specificMetricRecorderProvider: specificMetricRecorderProvider,
            multipleQueuesContainer: multipleQueuesContainer,
            emceeVersion: emceeVersion
        )
        self.jobStateProvider = MultipleQueuesJobStateProvider(
            multipleQueuesContainer: multipleQueuesContainer
        )
        self.jobResultsProvider = MultipleQueuesJobResultsProvider(
            multipleQueuesContainer: multipleQueuesContainer
        )
        let enqueueableBucketReceptor: EnqueueableBucketReceptor = MultipleQueuesEnqueueableBucketReceptor(
            bucketQueueFactory: bucketQueueFactory,
            multipleQueuesContainer: multipleQueuesContainer
        )
        self.runningQueueStateProvider = MultipleQueuesRunningQueueStateProvider(
            multipleQueuesContainer: multipleQueuesContainer
        )
        
        let dequeueableBucketSource: DequeueableBucketSource = DequeueableBucketSourceWithMetricSupport(
            dateProvider: dateProvider,
            dequeueableBucketSource: WorkerPermissionAwareDequeueableBucketSource(
                dequeueableBucketSource: MultipleQueuesDequeueableBucketSource(
                    multipleQueuesContainer: multipleQueuesContainer
                ),
                workerPermissionProvider: workerUtilizationStatusPoller
            ),
            jobStateProvider: jobStateProvider,
            logger: logger,
            queueStateProvider: runningQueueStateProvider,
            version: emceeVersion,
            specificMetricRecorderProvider: specificMetricRecorderProvider
        )
        let bucketResultAccepter: BucketResultAccepter = MultipleQueuesBucketResultAccepter(
            multipleQueuesContainer: multipleQueuesContainer
        )
        let stuckBucketsReenqueuer: StuckBucketsReenqueuer = MultipleQueuesStuckBucketsReenqueuer(
            multipleQueuesContainer: multipleQueuesContainer
        )
        
        self.testsEnqueuer = TestsEnqueuer(
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
            jobStateProvider: jobStateProvider,
            logger: logger,
            runningQueueStateProvider: runningQueueStateProvider,
            stuckBucketsReenqueuer: stuckBucketsReenqueuer,
            version: emceeVersion,
            specificMetricRecorderProvider: specificMetricRecorderProvider,
            globalMetricRecorder: globalMetricRecorder
        )
        self.bucketProvider = BucketProviderEndpoint(
            checkAfter: checkAgainTimeInterval,
            dequeueableBucketSource: dequeueableBucketSource,
            expectedPayloadSignature: payloadSignature,
            workerAlivenessProvider: workerAlivenessProvider
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            bucketResultAccepter: BucketResultAccepterWithMetricSupport(
                bucketResultAccepter: bucketResultAccepter,
                dateProvider: dateProvider,
                jobStateProvider: jobStateProvider,
                logger: logger,
                queueStateProvider: runningQueueStateProvider,
                version: emceeVersion,
                specificMetricRecorderProvider: specificMetricRecorderProvider
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
        self.deploymentDestinationsHandler = DeploymentDestinationsEndpoint(destinations: deploymentDestinations)
        self.toggleWorkersSharingEndpoint = ToggleWorkersSharingEndpoint(poller: workerUtilizationStatusPoller)
    }
    
    public func start() throws -> SocketModels.Port {
        httpRestServer.add(handler: RESTEndpointOf(bucketProvider))
        httpRestServer.add(handler: RESTEndpointOf(bucketResultRegistrar))
        httpRestServer.add(handler: RESTEndpointOf(deploymentDestinationsHandler))
        httpRestServer.add(handler: RESTEndpointOf(disableWorkerHandler))
        httpRestServer.add(handler: RESTEndpointOf(enableWorkerHandler))
        httpRestServer.add(handler: RESTEndpointOf(jobDeleteEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(jobResultsEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(jobStateEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(kickstartWorkerEndpoint))
        httpRestServer.add(handler: RESTEndpointOf(queueServerVersionHandler))
        httpRestServer.add(handler: RESTEndpointOf(scheduleTestsHandler))
        httpRestServer.add(handler: RESTEndpointOf(toggleWorkersSharingEndpoint))
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
        bucketSplitter: BucketSplitter,
        testEntryConfigurations: [TestEntryConfiguration],
        prioritizedJob: PrioritizedJob
    ) throws {
        try testsEnqueuer.enqueue(
            bucketSplitter: bucketSplitter,
            testEntryConfigurations: testEntryConfigurations,
            prioritizedJob: prioritizedJob
        )
    }
    
    public var isDepleted: Bool {
        return runningQueueStateProvider.runningQueueState.isDepleted
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
