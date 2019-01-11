import Basic
import Dispatch
import Foundation
import Logging
import Models
import SynchronousWaiter
import Version

public final class SynchronousQueueClient: QueueClientDelegate {
    
    public enum BucketFetchResult: Equatable {
        case bucket(Bucket)
        case queueIsEmpty
        case checkLater(TimeInterval)
        case workerHasBeenBlocked
    }
    
    private let queueClient: QueueClient
    private var registrationResult: Result<WorkerConfiguration, QueueClientError>?
    private var bucketFetchResult: Result<BucketFetchResult, QueueClientError>?
    private var bucketResultSendResult: Result<String, QueueClientError>?
    private var alivenessReportResult: Result<Bool, QueueClientError>?
    private var queueServerVersionResult: Result<Version, QueueClientError>?
    private var scheduleTestsResult: Result<String, QueueClientError>?
    private let syncQueue = DispatchQueue(label: "ru.avito.SynchronousQueueClient")
    private let requestTimeout: TimeInterval
    
    public init(serverAddress: String, serverPort: Int, workerId: String, requestTimeout: TimeInterval = 10) {
        self.requestTimeout = requestTimeout
        self.queueClient = QueueClient(serverAddress: serverAddress, serverPort: serverPort, workerId: workerId)
        self.queueClient.delegate = self
    }
    
    public func close() {
        queueClient.close()
    }
    
    // MARK: Public API
    
    public func registerWithServer() throws -> WorkerConfiguration {
        return try synchronize {
            registrationResult = nil
            try queueClient.registerWithServer()
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for registration with server") {
                self.registrationResult == nil
            }
            return try registrationResult!.dematerialize()
        }
    }
    
    public func fetchBucket(requestId: String) throws -> BucketFetchResult {
        return try synchronize {
            bucketFetchResult = nil
            return try runRetrying(times: 5) {
                try queueClient.fetchBucket(requestId: requestId)
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait bucket to return from server") {
                    self.bucketFetchResult == nil
                }
                return try bucketFetchResult!.dematerialize()
            }
        }
    }
    
    public func send(testingResult: TestingResult, requestId: String) throws -> String {
        return try synchronize {
            bucketResultSendResult = nil
            return try runRetrying(times: 5) {
                try queueClient.send(testingResult: testingResult, requestId: requestId)
                try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for bucket result send") {
                    self.bucketResultSendResult == nil
                }
                return try bucketResultSendResult!.dematerialize()
            }
        }
    }
    
    public func reportAliveness(bucketIdsBeingProcessedProvider: () -> (Set<String>)) throws {
        try synchronize {
            alivenessReportResult = nil
            try queueClient.reportAlive(bucketIdsBeingProcessedProvider: bucketIdsBeingProcessedProvider)
            try SynchronousWaiter.waitWhile(timeout: requestTimeout, description: "Wait for aliveness report") {
                self.alivenessReportResult == nil
            }
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
        jobId: JobId,
        testEntryConfigurations: [TestEntryConfiguration],
        requestId: String)
        throws -> String
    {
        return try synchronize {
            scheduleTestsResult = nil
            return try runRetrying(times: 5) {
                try queueClient.scheduleTests(
                    jobId: jobId,
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
    
    private func synchronize<T>(_ work: () throws -> T) rethrows -> T {
        return try syncQueue.sync {
            return try work()
        }
    }
    
    private func runRetrying<T>(times: UInt, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                Logger.error("Attempted to run \(retryIndex) of \(times), got an error: \(error)")
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
    }
    
    public func queueClient(_ sender: QueueClient, didReceiveWorkerConfiguration workerConfiguration: WorkerConfiguration) {
        registrationResult = Result.success(workerConfiguration)
    }
    
    public func queueClientQueueIsEmpty(_ sender: QueueClient) {
        bucketFetchResult = Result.success(.queueIsEmpty)
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
}
