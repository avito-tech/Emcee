import BalancingBucketQueue
import BucketQueue
import EventBus
import Extensions
import FileHasher
import Foundation
import Logging
import Models
import PortDeterminer
import RESTMethods
import ResultsCollector
import Swifter
import SynchronousWaiter
import WorkerAlivenessTracker

public final class QueueServer {
    private let balancingBucketQueue: BalancingBucketQueue
    private let bucketProvider: BucketProviderEndpoint
    private let bucketResultRegistrar: BucketResultRegistrar
    private let queueServerVersionHandler: QueueServerVersionEndpoint
    private let restServer: QueueHTTPRESTServer
    private let resultsCollector = ResultsCollector()
    private let workerAlivenessTracker: WorkerAlivenessTracker
    private let workerAlivenessEndpoint: WorkerAlivenessEndpoint
    private let workerRegistrar: WorkerRegistrar
    private let stuckBucketsPoller: StuckBucketsPoller
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let queueExhaustTimeAllowance: TimeInterval
    private let hasher = FileHasher(fileUrl: URL(fileURLWithPath: ProcessInfo.processInfo.executablePath))
    
    public init(
        eventBus: EventBus,
        workerConfigurations: WorkerConfigurations,
        reportAliveInterval: TimeInterval,
        numberOfRetries: UInt,
        newWorkerRegistrationTimeAllowance: TimeInterval = 60.0,
        queueExhaustTimeAllowance: TimeInterval = .infinity,
        checkAgainTimeInterval: TimeInterval,
        localPortDeterminer: LocalPortDeterminer,
        nothingToDequeueBehavior: NothingToDequeueBehavior)
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
        self.queueServerVersionHandler = QueueServerVersionEndpoint(
            versionProvider: hasher.hash
        )
    }
    
    public func start() throws -> Int {
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            dequeueBucketRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            bucketResultHandler: RESTEndpointOf(actualHandler: bucketResultRegistrar),
            reportAliveHandler: RESTEndpointOf(actualHandler: workerAlivenessEndpoint),
            versionHandler: RESTEndpointOf(actualHandler: queueServerVersionHandler)
        )
        
        stuckBucketsPoller.startTrackingStuckBuckets()
        
        let port = try restServer.start()
        log("Started queue server on port \(port)")
        return port
    }
    
    public func add(buckets: [Bucket], jobId: JobId) {
        balancingBucketQueue.enqueue(buckets: buckets, jobId: jobId)
        log("Enqueued \(buckets.count) buckets:")
        for bucket in buckets {
            log("-- \(bucket) with tests:")
            for testEntries in bucket.testEntries { log("-- -- \(testEntries)") }
        }
    }
    
    public func waitForJobToFinish(jobId: JobId) throws -> [TestingResult] {
        log("Waiting for workers to appear")
        try SynchronousWaiter.waitWhile(pollPeriod: 1, timeout: newWorkerRegistrationTimeAllowance, description: "Waiting workers to appear") {
            workerAlivenessTracker.hasAnyAliveWorker == false
        }
        
        log("Waiting for bucket queue to exhaust")
        try SynchronousWaiter.waitWhile(pollPeriod: 5, timeout: queueExhaustTimeAllowance, description: "Waiting for queue to exhaust") {
            guard workerAlivenessTracker.hasAnyAliveWorker else { throw QueueServerError.noWorkers }
            return !balancingBucketQueue.state.isDepleted
        }
        log("Bucket queue has exhaust")
        return resultsCollector.collectedResults
    }
    
    public func version() throws -> String {
        return try hasher.hash()
    }
}
