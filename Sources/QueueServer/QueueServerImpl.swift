import AutomaticTermination
import BalancingBucketQueue
import BucketQueue
import DateProvider
import Deployer
import DistWorkerModels
import Foundation
import Logging
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
import UniqueIdentifierGenerator
import WorkerAlivenessProvider

public final class QueueServerImpl: QueueServer {
    private let balancingBucketQueue: BalancingBucketQueue
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let deploymentDestinationsHandler: DeploymentDestinationsEndpoint
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
        payloadSignature: PayloadSignature,
        queueServerLock: QueueServerLock,
        requestSenderProvider: RequestSenderProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessPolicy: WorkerAlivenessPolicy,
        workerConfigurations: WorkerConfigurations,
        workersToUtilizeService: WorkersToUtilizeService,
        workerUtilizationStatusPoller: WorkerUtilizationStatusPoller
    ) {
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: automaticTerminationController,
            portProvider: localPortDeterminer
        )
        
        let alivenessPollingInterval: TimeInterval = 20
        let workerDetailsHolder = WorkerDetailsHolderImpl()
        
        self.workerAlivenessProvider = WorkerAlivenessProviderImpl(
            knownWorkerIds: workerConfigurations.workerIds
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
            ),
            workerPermissionProvider: workerUtilizationStatusPoller
        )
        self.balancingBucketQueue = balancingBucketQueueFactory.create()
        self.testsEnqueuer = TestsEnqueuer(
            bucketSplitInfo: bucketSplitInfo,
            dateProvider: dateProvider,
            enqueueableBucketReceptor: balancingBucketQueue,
            version: emceeVersion
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
            dateProvider: dateProvider,
            statefulStuckBucketsReenqueuer: balancingBucketQueue,
            version: emceeVersion
        )
        self.bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: DequeueableBucketSourceWithMetricSupport(
                dateProvider: dateProvider,
                dequeueableBucketSource: balancingBucketQueue,
                jobStateProvider: balancingBucketQueue,
                queueStateProvider: balancingBucketQueue,
                version: emceeVersion
            ),
            expectedPayloadSignature: payloadSignature
        )
        self.bucketResultRegistrar = BucketResultRegistrar(
            bucketResultAccepter: BucketResultAccepterWithMetricSupport(
                bucketResultAccepter: balancingBucketQueue,
                dateProvider: dateProvider,
                jobStateProvider: balancingBucketQueue,
                queueStateProvider: balancingBucketQueue,
                version: emceeVersion
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
        self.workerStatusEndpoint = WorkerStatusEndpoint(
            workerAlivenessProvider: workerAlivenessProvider
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
        self.workerAlivenessMetricCapturer = WorkerAlivenessMetricCapturer(
            dateProvider: dateProvider,
            reportInterval: .seconds(30),
            version: emceeVersion,
            workerAlivenessProvider: workerAlivenessProvider
        )
        self.workersToUtilizeEndpoint = WorkersToUtilizeEndpoint(
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
