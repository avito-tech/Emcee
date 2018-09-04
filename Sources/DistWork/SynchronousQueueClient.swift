import Basic
import Dispatch
import Foundation
import Logging
import Models
import SynchronousWaiter
import Utility

public final class SynchronousQueueClient: QueueClientDelegate {
    
    public enum BucketFetchResult {
        case bucket(Bucket)
        case queueIsEmpty
        case checkLater(TimeInterval)
        case workerHasBeenBlocked
    }
    
    private var acceptedBucketResultIds: [String]
    private let queueClient: QueueClient
    private var registrationResult: Result<WorkerConfiguration, QueueClientError>?
    private var bucketFetchResult: Result<BucketFetchResult, QueueClientError>?
    private let syncQueue = DispatchQueue(label: "ru.avito.SynchronousQueueClient")
    
    public init(serverAddress: String, serverPort: Int, workerId: String) {
        self.acceptedBucketResultIds = []
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
            try SynchronousWaiter.waitWhile(timeout: 10) { self.registrationResult == nil }
            return try registrationResult!.dematerialize()
        }
    }
    
    public func fetchBucket(requestId: String) throws -> BucketFetchResult {
        return try synchronize {
            bucketFetchResult = nil
            return try runRetrying(times: 5) {
                try queueClient.fetchBucket(requestId: requestId)
                try SynchronousWaiter.waitWhile { self.bucketFetchResult == nil }
                return try bucketFetchResult!.dematerialize()
            }
        }
    }
    
    public func send(bucketResult: BucketResult, requestId: String) throws {
        try synchronize {
            try queueClient.send(bucketResult: bucketResult, requestId: requestId)
            try SynchronousWaiter.waitWhile(timeout: 10, description: "Wait for bucket result send") {
                acceptedBucketResultIds.contains(bucketResult.testingResult.bucket.bucketId)
            }
        } as Void
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
                log("Attempted to run \(retryIndex) or \(times), got an error: \(error)")
                sleep(1)
            }
        }
        return try work()
    }
    
    // MARK: - Queue Delegate
    
    public func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        registrationResult = Result.failure(error)
        bucketFetchResult = Result.failure(error)
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
        acceptedBucketResultIds.append(bucketId)
    }
}
