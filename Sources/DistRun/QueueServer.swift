import EventBus
import Extensions
import Foundation
import Logging
import Models
import RESTMethods
import ScheduleStrategy
import Swifter
import SynchronousWaiter

public final class QueueServer {
    private let eventBus: EventBus
    private let buckets: [Bucket]
    private var queue: [Bucket]
    private var dequeuedBuckets = Set<DequeuedBucket>()
    private var workerAliveReportTimestamps = [String: Date]()
    
    public private(set) var testingResults = [TestingResult]()
    private var workerIdToRunConfiguration: [String: WorkerConfiguration]
    
    private let restServer = QueueHTTPRESTServer()
    
    private let syncQueue = DispatchQueue(label: "ru.avito.QueueServer")
    private var stuckDequeuedBucketsTimer: DispatchSourceTimer?
    private let stuckDequeuedBucketsTimerQueue = DispatchQueue(label: "ru.avito.QueueServer.stuckBucketsTimerQueue")
    
    public init(eventBus: EventBus, queue: [Bucket], workerIdToRunConfiguration: [String: WorkerConfiguration]) {
        self.eventBus = eventBus
        self.buckets = queue
        self.queue = queue
        self.workerIdToRunConfiguration = workerIdToRunConfiguration
    }
    
    deinit {
        stopProcessingStuckDequeuedBuckets()
    }
    
    public func port() throws -> Int {
        return try restServer.port()
    }
    
    public func start() throws {
        restServer.setEndpoints(
            registerWorker: QueueHTTPRESTServer.Endpoint<RegisterWorkerRequest>(registerWorkerRequestHandler),
            getBucket: QueueHTTPRESTServer.Endpoint<BucketFetchRequest>(getBucketRequestHandler),
            bucketResult: QueueHTTPRESTServer.Endpoint<BucketResultRequest>(bucketResultHandler),
            reportAlive: QueueHTTPRESTServer.Endpoint<ReportAliveRequest>(reportWorkerIsAliveHandler))
        
        try restServer.start()
        let port = try restServer.port()
        log("Started queue server on port \(port) with \(buckets.count) buckets:")
        buckets.forEach { bucket in
            log("Bucket: \(bucket), tests: \(bucket.testEntries)")
        }
        
        startProcessingStuckDequeuedBuckets()
    }
    
    public func waitForAllResultsToCome() throws {
        log("Waiting for queue to be empty")
        try SynchronousWaiter.waitWhile(pollPeriod: 1) {
            guard hasAliveWorkers() else { throw QueueServerError.noWorkers }
            return !processedAllBuckets()
        }
        log("Queue has finished waiting for results")
    }
    
    // MARK: - Conditions
    
    private func processedAllBuckets() -> Bool {
        return syncQueue.sync {
            return queue.isEmpty && dequeuedBuckets.isEmpty
        }
    }
    
    private func hasAliveWorkers() -> Bool {
        return !workerIdToRunConfiguration.isEmpty
    }
    
    // MARK: - Request Handlers
    
    private func registerWorkerRequestHandler(registerRequest: RegisterWorkerRequest) throws -> RESTResponse {
        log("New worker with id: \(registerRequest.workerId)")
        workerDidReportAliveness(workerId: registerRequest.workerId)
        guard let workerConfiguration = workerIdToRunConfiguration[registerRequest.workerId] else {
            log("Can't locate configuration for worker \(registerRequest.workerId). Will return server error.")
            throw QueueServerError.missingWorkerConfigurationForWorkerId(registerRequest.workerId)
        }
        return .workerRegisterSuccess(workerConfiguration: workerConfiguration)
    }
    
    private func getBucketRequestHandler(fetchRequest: BucketFetchRequest) -> RESTResponse {
        let dequeueResult = dequeuedBucket(requestId: fetchRequest.requestId, workerId: fetchRequest.workerId)
        switch dequeueResult {
        case .queueIsEmpty:
            return .queueIsEmpty
        case .queueIsEmptyButNotResultsAreAvailable:
            let checkAfter: TimeInterval = queue.isEmpty ? 10 : 30
            return .checkAgainLater(checkAfter: checkAfter)
        case .dequeuedBucket(let dequeuedBucket):
            return .bucketDequeued(bucket: dequeuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
    
    private func bucketResultHandler(decodedRequest: BucketResultRequest) throws -> RESTResponse {
        log("Decoded \(RESTMethod.bucketResult) from \(decodedRequest.workerId): \(decodedRequest.testingResult)")
        try accept(bucketResultRequest: decodedRequest)
        return .bucketResultAccepted(bucketId: decodedRequest.testingResult.bucketId)
    }
    
    private func reportWorkerIsAliveHandler(decodedRequest: ReportAliveRequest) -> RESTResponse {
        workerDidReportAliveness(workerId: decodedRequest.workerId)
        return .aliveReportAccepted
    }
    
    // MARK: - Helpers
    
    private func accept(bucketResultRequest request: BucketResultRequest) throws {
        guard let dequeuedBucket = previouslyDequeuedBucket(requestId: request.requestId, workerId: request.workerId) else {
            throw BucketResultRequestError.noDequeuedBucket(requestId: request.requestId, workerId: request.workerId)
        }
        let requestTestEntries = Set(request.testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(dequeuedBucket.bucket.testEntries)
        guard requestTestEntries == expectedTestEntries else {
            blockWorker(workerId: request.workerId)
            throw BucketResultRequestError.notAllResultsAvailable(
                requestId: request.requestId,
                workerId: request.workerId,
                expectedTestEntries: dequeuedBucket.bucket.testEntries,
                providedResults: request.testingResult.unfilteredResults)
        }
        
        didReceive(testingResult: request.testingResult, previouslyDequeuedBucket: dequeuedBucket)
    }
    
    private func didReceive(testingResult: TestingResult, previouslyDequeuedBucket: DequeuedBucket) {
        syncQueue.sync {
            testingResults.append(testingResult)
            eventBus.post(event: .didObtainTestingResult(testingResult))
            
            log("Accepted result for bucket: \(testingResult.bucketId), dequeued buckets count: \(dequeuedBuckets.count): \(dequeuedBuckets)")
            if dequeuedBuckets.remove(previouslyDequeuedBucket) != nil {
                log("Removed dequeued bucket as we have result for it now: \(previouslyDequeuedBucket) from dequeued buckets: \(dequeuedBuckets)")
            } else {
                log("ERROR: Failed to remove dequeued bucket: \(previouslyDequeuedBucket) from dequeued buckets: \(dequeuedBuckets)")
            }
            logQueueSize()
        }
    }
    
    private func logQueueSize() {
        log("Queue size: \(queue.count), dequeued buckets size: \(dequeuedBuckets.count)")
    }
    
    private func workerDidReportAliveness(workerId: String) {
        syncQueue.sync {
            workerAliveReportTimestamps[workerId] = Date()
        }
    }
    
    private func blockWorker(workerId: String) {
        syncQueue.sync {
            log("WARNING: Blocking worker id from executing buckets: \(workerId)", color: .yellow)
            workerIdToRunConfiguration.removeValue(forKey: workerId)
            workerAliveReportTimestamps.removeValue(forKey: workerId)
        }
    }
    
    // MARK: - Utility Methods
    
    private func dequeuedBucket(requestId: String, workerId: String) -> DequeueResult {
        let workerConfiguration = syncQueue.sync { workerIdToRunConfiguration[workerId] }
        guard workerConfiguration != nil else {
            return .workerBlocked
        }
        
        if processedAllBuckets() {
            log("Queue is empty and all dequeued bucket results have been received. Retuning empty queue result instead of dequeueing bucket", color: .green)
            return .queueIsEmpty
        }
        
        if let previouslyDequeuedBucket = previouslyDequeuedBucket(requestId: requestId, workerId: workerId) {
            log("Provided previously dequeued bucket: \(previouslyDequeuedBucket)")
            return .dequeuedBucket(previouslyDequeuedBucket)
        }
        
        return syncQueue.sync {
            if queue.isEmpty {
                return .queueIsEmptyButNotResultsAreAvailable
            } else {
                let bucket = queue.removeFirst()
                let dequeuedBucket = DequeuedBucket(bucket: bucket, workerId: workerId, requestId: requestId)
                dequeuedBuckets.insert(dequeuedBucket)
                log("Dequeued new bucket: \(dequeuedBucket)")
                logQueueSize()
                return .dequeuedBucket(dequeuedBucket)
            }
        }
    }
    
    private func previouslyDequeuedBucket(requestId: String, workerId: String) -> DequeuedBucket? {
        return syncQueue.sync {
            return dequeuedBuckets.first { $0.requestId == requestId && $0.workerId == workerId }
        }
    }
    
    // MARK: - Processing Stuck Dequeued Buckets
    
    private func startProcessingStuckDequeuedBuckets() {
        stopProcessingStuckDequeuedBuckets()
        let timer = DispatchSource.makeTimerSource(queue: stuckDequeuedBucketsTimerQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            self?.processStuckDequeuedBuckets()
        }
        timer.resume()
        stuckDequeuedBucketsTimer = timer
    }
    
    private func stopProcessingStuckDequeuedBuckets() {
        stuckDequeuedBucketsTimer?.cancel()
    }
    
    /**
     * This method looks for DequeuedBucket objects with dequeuedAt date passed the timeout to get the results back.
     * This may happen if agent fetches a bucket and then it does not return the result due to crash, etc.
     * When queue server finds such DequeuedBucket-s, it will return their corresponding Bucket-s back to the queue.
     */
    private func processStuckDequeuedBuckets() {
        syncQueue.sync {
            let dequeuedBucketsToReEnqueue = onSyncQueue_dequeuedBucketsToReEnqueue()
            if dequeuedBucketsToReEnqueue.isEmpty { return }
            
            log("Detected dequeued buckets with no results: \(dequeuedBucketsToReEnqueue)")
            log("Old dequeued bucket contents: \(dequeuedBuckets)")
            dequeuedBuckets.subtract(dequeuedBucketsToReEnqueue)
            log("New dequeued bucket contents: \(dequeuedBuckets)")
            let strategy = IndividualScheduleStrategy()
            let newBuckets = dequeuedBucketsToReEnqueue.flatMap {
                strategy.generateIndividualBuckets(
                    testEntries: $0.bucket.testEntries,
                    testDestination: $0.bucket.testDestination,
                    toolResources: $0.bucket.toolResources,
                    buildArtifacts: $0.bucket.buildArtifacts)
            }
            queue.append(contentsOf: newBuckets)
            log("Returned \(dequeuedBucketsToReEnqueue.count) buckets to the queue by crushing it to \(newBuckets.count) buckets: \(newBuckets)")
            logQueueSize()
        }
    }
    
    private func onSyncQueue_workersWhoDidNotReportAliveness() -> Set<String> {
        let notAlive = workerAliveReportTimestamps.filter { (workerId, latestAliveDate) -> Bool in
            guard let workerConfiguration = workerIdToRunConfiguration[workerId] else {
                log("Unable to get worker configuration for worker id \(workerId), will consider this worker as not alive.")
                workerIdToRunConfiguration.removeValue(forKey: workerId)
                return true
            }
            let silenceDuration = Date().timeIntervalSince(latestAliveDate)
            // allow worker some additinal time to perform a "i'm alive" report, e.g. to compensate a network latency
            let additionalTimeToPerformWorkerIsAliveReport = 10.0
            let maximumNotReportingDuration = workerConfiguration.reportAliveInterval + additionalTimeToPerformWorkerIsAliveReport
            return silenceDuration > maximumNotReportingDuration
        }
        return Set(notAlive.keys)
    }
    
    private func onSyncQueue_dequeuedBucketsToReEnqueue() -> Set<DequeuedBucket> {
        let workersInSilence = onSyncQueue_workersWhoDidNotReportAliveness()
        let stuckDequeuedBuckets = dequeuedBuckets.filter { dequeuedBucket in
            // if worker died/did not respond in time, we consider its buckets to be stuck
            return workersInSilence.contains(dequeuedBucket.workerId)
        }
        let notBlockedWorkers = Set(workerIdToRunConfiguration.keys)
        let dequeuedBucketsFromBlockedWorkers = dequeuedBuckets.filter { dequeuedBucket in
            return !notBlockedWorkers.contains(dequeuedBucket.workerId)
        }
        return stuckDequeuedBuckets.union(dequeuedBucketsFromBlockedWorkers)
    }
}
