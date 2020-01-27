import Dispatch
import Foundation
import Logging
import Models
import RESTMethods
import SynchronousWaiter
import RequestSender
import Version

public final class SynchronousQueueClient: QueueClientDelegate {
    public enum BucketFetchResult: Equatable {
        case bucket(Bucket)
        case queueIsEmpty
        case checkLater(TimeInterval)
        case workerHasBeenBlocked
        case workerConsideredNotAlive
    }
    
    private let queueClient: QueueClient
    private var bucketFetchResult: Either<BucketFetchResult, QueueClientError>?
    private var scheduleTestsResult: Either<RequestId, QueueClientError>?
    private var jobResultsResult: Either<JobResults, QueueClientError>?
    private var jobStateResult: Either<JobState, QueueClientError>?
    private var jobDeleteResult: Either<JobId, QueueClientError>?
    private let syncQueue = DispatchQueue(label: "ru.avito.SynchronousQueueClient")
    private let requestTimeout: TimeInterval
    private let networkRequestRetryCount: Int
    
    public init(
        queueServerAddress: SocketAddress,
        requestTimeout: TimeInterval = 10,
        networkRequestRetryCount: Int = 5
    ) {
        self.requestTimeout = requestTimeout
        self.networkRequestRetryCount = networkRequestRetryCount
        self.queueClient = QueueClient(
            queueServerAddress: queueServerAddress,
            requestSenderProvider: DefaultRequestSenderProvider()
        )
        self.queueClient.delegate = self
    }
    
    public func close() {
        queueClient.close()
    }
    
    // MARK: Public API
    
    public func fetchBucket(requestId: RequestId, workerId: WorkerId, payloadSignature: PayloadSignature) throws -> BucketFetchResult {
        return try synchronize {
            bucketFetchResult = nil
            return try runRetrying {
                try queueClient.fetchBucket(requestId: requestId, workerId: workerId, payloadSignature: payloadSignature)
                try SynchronousWaiter().waitWhile(timeout: requestTimeout, description: "Wait bucket to return from server") {
                    self.bucketFetchResult == nil
                }
                return try bucketFetchResult!.dematerialize()
            }
        }
    }
    
    public func scheduleTests(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategyType,
        testEntryConfigurations: [TestEntryConfiguration],
        requestId: RequestId)
        throws -> RequestId
    {
        return try synchronize {
            scheduleTestsResult = nil
            return try runRetrying {
                try queueClient.scheduleTests(
                    prioritizedJob: prioritizedJob,
                    scheduleStrategy: scheduleStrategy,
                    testEntryConfigurations: testEntryConfigurations,
                    requestId: requestId
                )
                try SynchronousWaiter().waitWhile(timeout: requestTimeout, description: "Wait for tests to be scheduled") {
                    self.scheduleTestsResult == nil
                }
                return try scheduleTestsResult!.dematerialize()
            }
        }
    }
    
    public func jobResults(jobId: JobId) throws -> JobResults {
        return try synchronize {
            jobResultsResult = nil
            return try runRetrying {
                try queueClient.fetchJobResults(jobId: jobId)
                try SynchronousWaiter().waitWhile(timeout: requestTimeout, description: "Wait for \(jobId) job results") {
                    self.jobResultsResult == nil
                }
                return try jobResultsResult!.dematerialize()
            }
        }
    }
    
    public func jobState(jobId: JobId) throws -> JobState {
        return try synchronize {
            jobStateResult = nil
            return try runRetrying {
                try queueClient.fetchJobState(jobId: jobId)
                try SynchronousWaiter().waitWhile(timeout: requestTimeout, description: "Wait for \(jobId) job state") {
                    self.jobStateResult == nil
                }
                return try jobStateResult!.dematerialize()
            }
        }
    }
    
    public func delete(jobId: JobId) throws -> JobId {
        return try synchronize {
            jobDeleteResult = nil
            try queueClient.deleteJob(jobId: jobId)
            try SynchronousWaiter().waitWhile(timeout: requestTimeout, description: "Wait for job \(jobId) to be deleted") {
                self.jobDeleteResult == nil
            }
            return try jobDeleteResult!.dematerialize()
        }
    }
    
    // MARK: - Private
    
    private func synchronize<T>(_ work: () throws -> T) rethrows -> T {
        return try syncQueue.sync {
            return try work()
        }
    }
    
    private func runRetrying<T>(_ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< networkRequestRetryCount {
            Logger.verboseDebug("Attempting to send request: #\(retryIndex + 1) of \(networkRequestRetryCount)")
            do {
                return try work()
            } catch {
                Logger.error("Failed to send request with error: \(error)")
                SynchronousWaiter().wait(timeout: 1.0, description: "Pause between request retries")
            }
        }
        return try work()
    }
    
    // MARK: - Queue Delegate
    
    public func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        bucketFetchResult = Either.error(error)
        scheduleTestsResult = Either.error(error)
        jobResultsResult = Either.error(error)
        jobStateResult = Either.error(error)
        jobDeleteResult = Either.error(error)
    }
    
    public func queueClientQueueIsEmpty(_ sender: QueueClient) {
        bucketFetchResult = Either.success(.queueIsEmpty)
    }
    
    public func queueClientWorkerConsideredNotAlive(_ sender: QueueClient) {
        bucketFetchResult = Either.success(.workerConsideredNotAlive)
    }
    
    public func queueClientWorkerHasBeenBlocked(_ sender: QueueClient) {
        bucketFetchResult = Either.success(.workerHasBeenBlocked)
    }
    
    public func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval) {
        bucketFetchResult = Either.success(.checkLater(after))
    }
    
    public func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket) {
        bucketFetchResult = Either.success(.bucket(bucket))
    }

    public func queueClientDidScheduleTests(_ sender: QueueClient, requestId: RequestId) {
        scheduleTestsResult = Either.success(requestId)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchJobState jobState: JobState) {
        jobStateResult = Either.success(jobState)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults) {
        jobResultsResult = Either.success(jobResults)
    }
    
    public func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId) {
        jobDeleteResult = Either.success(jobId)
    }
}
