import BucketQueue
import EventBus
import Extensions
import Foundation
import Logging
import Models
import RESTMethods
import Swifter
import SynchronousWaiter
import WorkerAlivenessTracker

public final class QueueServer {
    private let bucketProvider: BucketProviderEndpoint
    private let bucketQueue: BucketQueue
    private let bucketResultRegistrar: BucketResultRegistrar
    private let restServer = QueueHTTPRESTServer()
    private let resultsCollector = ResultsCollector()
    private let workerAlivenessTracker: WorkerAlivenessTracker
    private let workerRegistrar: WorkerRegistrar
    private let stuckBucketsEnqueuer: StuckBucketsPoller
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let queueExhaustTimeAllowance: TimeInterval
    
    public init(
        eventBus: EventBus,
        workerConfigurations: WorkerConfigurations,
        reportAliveInterval: TimeInterval,
        numberOfRetries: UInt,
        newWorkerRegistrationTimeAllowance: TimeInterval = 60.0,
        queueExhaustTimeAllowance: TimeInterval = .infinity)
    {
        self.workerAlivenessTracker = WorkerAlivenessTracker(reportAliveInterval: reportAliveInterval, additionalTimeToPerformWorkerIsAliveReport: 10.0)
        self.workerRegistrar = WorkerRegistrar(workerConfigurations: workerConfigurations, workerAlivenessTracker: workerAlivenessTracker)
        self.bucketQueue = BucketQueueFactory.create(
            workerAlivenessProvider: workerAlivenessTracker,
            testHistoryTracker: TestHistoryTrackerImpl(
                numberOfRetries: numberOfRetries,
                testHistoryStorage: TestHistoryStorageImpl()
            )
        )
        self.stuckBucketsEnqueuer = StuckBucketsPoller(bucketQueue: bucketQueue)
        self.bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue)
        self.bucketResultRegistrar = BucketResultRegistrar(bucketQueue: bucketQueue, eventBus: eventBus, resultsCollector: resultsCollector, workerAlivenessTracker: workerAlivenessTracker)
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.queueExhaustTimeAllowance = queueExhaustTimeAllowance
    }
    
    public func start() throws -> Int {
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            bucketFetchRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            bucketResultHandler: RESTEndpointOf(actualHandler: bucketResultRegistrar),
            reportAliveHandler: RESTEndpointOf(actualHandler: WorkerAlivenessEndpoint(alivenessTracker: workerAlivenessTracker)))
        
        stuckBucketsEnqueuer.startTrackingStuckBuckets()
        
        let port = try restServer.start()
        log("Started queue server on port \(port)")
        return port
    }
    
    public func add(buckets: [Bucket]) {
        bucketQueue.enqueue(buckets: buckets)
        log("Enqueued \(buckets.count) buckets:")
        for bucket in buckets {
            log("-- \(bucket) with tests:")
            for testEntries in bucket.testEntries { log("-- -- \(testEntries)") }
        }
    }
    
    public func waitForQueueToFinish() throws -> [TestingResult] {
        log("Waiting for workers to appear")
        try SynchronousWaiter.waitWhile(pollPeriod: 1, timeout: newWorkerRegistrationTimeAllowance, description: "Waiting workers to appear") {
            workerAlivenessTracker.hasAnyAliveWorker == false
        }
        
        log("Waiting for bucket queue to exhaust")
        try SynchronousWaiter.waitWhile(pollPeriod: 5, timeout: queueExhaustTimeAllowance, description: "Waiting for queue to exhaust") {
            guard workerAlivenessTracker.hasAnyAliveWorker else { throw QueueServerError.noWorkers }
            return !bucketQueue.state.isDepleted
        }
        log("Bucket queue has exhaust")
        return resultsCollector.collectedResults
    }
}
