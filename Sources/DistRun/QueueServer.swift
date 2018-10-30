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
    
    private let server = HttpServer()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private let syncQueue = DispatchQueue(label: "ru.avito.QueueServer")
    private var stuckDequeuedBucketsTimer: DispatchSourceTimer?
    private let stuckDequeuedBucketsTimerQueue = DispatchQueue(label: "ru.avito.QueueServer.stuckBucketsTimerQueue")
    
    public init(eventBus: EventBus, queue: [Bucket], workerIdToRunConfiguration: [String: WorkerConfiguration]) {
        self.eventBus = eventBus
        self.buckets = queue
        self.queue = queue
        self.workerIdToRunConfiguration = workerIdToRunConfiguration
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    deinit {
        stopProcessingStuckDequeuedBuckets()
    }
    
    public func port() throws -> Int {
        return try server.port()
    }
    
    public func start() throws {
        server[RESTMethod.registerWorker.withPrependingSlash] = registerWorkerRequestHandler
        server[RESTMethod.getBucket.withPrependingSlash] = getBucketRequestHandler
        server[RESTMethod.bucketResult.withPrependingSlash] = bucketResultHandler
        server[RESTMethod.reportAlive.withPrependingSlash] = reportWorkerIsAliveHandler
        
        try server.start(0, forceIPv4: false, priority: .default)
        let port = try server.port()
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
    
    private func processedAllBuckets() -> Bool {
        return syncQueue.sync {
            return queue.isEmpty && dequeuedBuckets.isEmpty
        }
    }
    
    private func hasAliveWorkers() -> Bool {
        return !workerIdToRunConfiguration.isEmpty
    }
    
    // MARK: - Request Handlers
    
    private func registerWorkerRequestHandler(request: HttpRequest) -> HttpResponse {
        let requestData = Data(bytes: request.body)
        do {
            let registerRequest = try decoder.decode(RegisterWorkerRequest.self, from: requestData)
            log("New worker with id: \(registerRequest.workerId)")
            workerDidReportAliveness(workerId: registerRequest.workerId)
            guard let workerConfiguration = workerIdToRunConfiguration[registerRequest.workerId] else {
                log("Can't locate configuration for worker \(registerRequest.workerId). Will return server error.")
                return .internalServerError
            }
            return generateJsonResponse(.workerRegisterSuccess(workerConfiguration: workerConfiguration))
        } catch {
            log("Failed to decode \(request.path) data: \(error). Will return server error response.")
            return .internalServerError
        }
    }
    
    private func getBucketRequestHandler(request: HttpRequest) -> HttpResponse {
        let requestData = Data(bytes: request.body)
        do {
            let fetchRequest = try decoder.decode(BucketFetchRequest.self, from: requestData)
            let dequeueResult = dequeuedBucket(requestId: fetchRequest.requestId, workerId: fetchRequest.workerId)
            switch dequeueResult {
            case .queueIsEmpty:
                return generateJsonResponse(.queueIsEmpty)
            case .queueIsEmptyButNotResultsAreAvailable:
                let checkAfter: TimeInterval = queue.isEmpty ? 10 : 30
                return generateJsonResponse(.checkAgainLater(checkAfter: checkAfter))
            case .dequeuedBucket(let dequeuedBucket):
                return generateJsonResponse(.bucketDequeued(bucket: dequeuedBucket.bucket))
            case .workerBlocked:
                return generateJsonResponse(.workerBlocked)
            }
        } catch {
            log("Failed to decode \(request.path) data: \(error). Will return server error response.")
            return .internalServerError
        }
    }
    
    private func bucketResultHandler(request: HttpRequest) -> HttpResponse {
        let requestData = Data(bytes: request.body)
        do {
            let decodedRequest = try decoder.decode(BucketResultRequest.self, from: requestData)
            log("Decoded \(RESTMethod.bucketResult) from \(decodedRequest.workerId): \(decodedRequest.testingResult)")
            try acceptBucketResultRequest(decodedRequest)
            return generateJsonResponse(.bucketResultAccepted(bucketId: decodedRequest.testingResult.bucketId))
        } catch {
            log("Failed to process \(request.path) data: \(error). Will return server error response.")
            return .internalServerError
        }
    }
    
    private func reportWorkerIsAliveHandler(request: HttpRequest) -> HttpResponse {
        let requestData = Data(bytes: request.body)
        do {
            let decodedRequest = try decoder.decode(ReportAliveRequest.self, from: requestData)
            workerDidReportAliveness(workerId: decodedRequest.workerId)
            return .accepted
        } catch {
            log("Failed to process \(request.path) data: \(error). Will return server error response.")
            return .internalServerError
        }
    }
    
    private func acceptBucketResultRequest(_ request: BucketResultRequest) throws {
        guard let dequeuedBucket = previouslyDequeuedBucket(requestId: request.requestId, workerId: request.workerId) else {
            throw BucketResultRequestError.noDequeuedBucket(requestId: request.requestId, workerId: request.workerId)
        }
        let requestTestEntries = Set(request.testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(dequeuedBucket.bucket.testEntries)
        guard requestTestEntries == expectedTestEntries else {
            block(workerId: request.workerId, reason: "Worker provided incorrect or ")
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
                log("Removing dequeued bucket as we have result for it now: \(dequeuedBucket) from dequeued buckets: \(dequeuedBuckets)")
            } else {
                log("ERROR: Failed to remove dequeued bucket: \(dequeuedBucket) from dequeued buckets: \(dequeuedBuckets)")
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
    
    private func block(workerId: String, reason: String) {
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
    
    private func generateJsonResponse(_ response: RESTResponse) -> HttpResponse {
        do {
            let data = try self.encoder.encode(response)
            return .raw(200, "OK", ["Content-Type": "application/json"]) { try $0.write(data) }
        } catch {
            log("Failed to generate JSON response: \(error). Will return server error response.")
            return .internalServerError
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
                    testDestination: $0.bucket.testDestination)
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
