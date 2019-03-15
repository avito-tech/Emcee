import Basic
import Dispatch
import Foundation
import Logging
import Models
import RESTMethods
import SynchronousWaiter
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
    private var registrationResult: Result<WorkerConfiguration, QueueClientError>?
    private var bucketFetchResult: Result<BucketFetchResult, QueueClientError>?
    private var bucketResultSendResult: Result<String, QueueClientError>?
    private var alivenessReportResult: Result<Bool, QueueClientError>?
    private var queueServerVersionResult: Result<Version, QueueClientError>?
    private var scheduleTestsResult: Result<String, QueueClientError>?
    private var jobResultsResult: Result<JobResults, QueueClientError>?
    private var jobStateResult: Result<JobState, QueueClientError>?
    private var jobDeleteResult: Result<JobId, QueueClientError>?
    private let syncQueue = DispatchQueue(label: "ru.avito.SynchronousQueueClient")
    private let requestTimeout: TimeInterval
    private let networkRequestRetryCount: Int
    
    public init(
        queueServerAddress: SocketAddress,
        requestTimeout: TimeInterval = 10,
        networkRequestRetryCount: Int = 5)
    {
        self.requestTimeout = requestTimeout
        self.networkRequestRetryCount = networkRequestRetryCount
        self.queueClient = QueueClient(queueServerAddress: queueServerAddress)
        self.queueClient.delegate = self
    }
    
    public func close() {
        queueClient.close()
    }
    
    // MARK: Public API
    
    public func registerWithServer(workerId: String) throws -> WorkerConfiguration {
        return try synchronize {
            registrationResult = nil
            try queueClient.registerWithServer(workerId: workerId)
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for registration with server") {
                self.registrationResult == nil
            }
            return try registrationResult!.dematerialize()
        }
    }
    
    public func fetchBucket(requestId: String, workerId: String) throws -> BucketFetchResult {
        return try synchronize {
            bucketFetchResult = nil
            return try runRetrying {
                try queueClient.fetchBucket(requestId: requestId, workerId: workerId)
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait bucket to return from server") {
                    self.bucketFetchResult == nil
                }
                return try bucketFetchResult!.dematerialize()
            }
        }
    }
    
    public func send(testingResult: TestingResult, requestId: String, workerId: String) throws -> String {
        return try synchronize {
            bucketResultSendResult = nil
            return try runRetrying {
                try queueClient.send(
                    testingResult: testingResult,
                    requestId: requestId,
                    workerId: workerId
                )
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for bucket result send") {
                    self.bucketResultSendResult == nil
                }
                return try bucketResultSendResult!.dematerialize()
            }
        }
    }
    
    public func reportAliveness(bucketIdsBeingProcessedProvider: () -> (Set<String>), workerId: String) throws {
        try synchronize {
            alivenessReportResult = nil
            try runRetrying {
                try queueClient.reportAlive(
                    bucketIdsBeingProcessedProvider: bucketIdsBeingProcessedProvider,
                    workerId: workerId
                )
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for aliveness report") {
                    self.alivenessReportResult == nil
                }
            } as Void
        } as Void
    }
    
    public func fetchQueueServerVersion() throws -> Version {
        return try synchronize {
            queueServerVersionResult = nil
            try queueClient.fetchQueueServerVersion()
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for queue server version") {
                self.queueServerVersionResult == nil
            }
            return try queueServerVersionResult!.dematerialize()
        }
    }
    
    public func scheduleTests(
        prioritizedJob: PrioritizedJob,
        testEntryConfigurations: [TestEntryConfiguration],
        requestId: String)
        throws -> String
    {
        return try synchronize {
            scheduleTestsResult = nil
            return try runRetrying {
                try queueClient.scheduleTests(
                    prioritizedJob: prioritizedJob,
                    testEntryConfigurations: testEntryConfigurations,
                    requestId: requestId
                )
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for tests to be scheduled") {
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
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for \(jobId) job results") {
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
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for \(jobId) job state") {
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
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for job \(jobId) to be deleted") {
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
            do {
                return try work()
            } catch {
                Logger.error("Attempted to run \(retryIndex) of \(networkRequestRetryCount), got an error: \(error)")
                SynchronousWaiter.wait(timeout: 1.0)
            }
        }
        return try work()
    }
    
    // MARK: - Queue Delegate
    
    public func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        registrationResult = Result.failure(error)
        bucketFetchResult = Result.failure(error)
        alivenessReportResult = Result.failure(error)
        bucketResultSendResult = Result.failure(error)
        queueServerVersionResult = Result.failure(error)
        scheduleTestsResult = Result.failure(error)
        jobResultsResult = Result.failure(error)
        jobStateResult = Result.failure(error)
        jobDeleteResult = Result.failure(error)
    }
    
    public func queueClient(_ sender: QueueClient, didReceiveWorkerConfiguration workerConfiguration: WorkerConfiguration) {
        registrationResult = Result.success(workerConfiguration)
    }
    
    public func queueClientQueueIsEmpty(_ sender: QueueClient) {
        bucketFetchResult = Result.success(.queueIsEmpty)
    }
    
    public func queueClientWorkerConsideredNotAlive(_ sender: QueueClient) {
        bucketFetchResult = Result.success(.workerConsideredNotAlive)
    }
    
    public func queueClientWorkerHasBeenBlocked(_ sender: QueueClient) {
        bucketFetchResult = Result.success(.workerHasBeenBlocked)
    }
    
    public func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval) {
        bucketFetchResult = Result.success(.checkLater(after))
    }
    
    public func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket) {
        bucketFetchResult = Result.success(.bucket(bucket))
    }
    
    public func queueClient(_ sender: QueueClient, serverDidAcceptBucketResult bucketId: String) {
        bucketResultSendResult = Result.success(bucketId)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchQueueServerVersion version: Version) {
        queueServerVersionResult = Result.success(version)
    }
    
    public func queueClientWorkerHasBeenIndicatedAsAlive(_ sender: QueueClient) {
        alivenessReportResult = Result.success(true)
    }
    
    public func queueClientDidScheduleTests(_ sender: QueueClient, requestId: String) {
        scheduleTestsResult = Result.success(requestId)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchJobState jobState: JobState) {
        jobStateResult = Result.success(jobState)
    }
    
    public func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults) {
        jobResultsResult = Result.success(jobResults)
    }
    
    public func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId) {
        jobDeleteResult = Result.success(jobId)
    }
}
