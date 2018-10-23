import Dispatch
import EventBus
import Foundation
import Logging
import Models
import PluginManager
import Scheduler
import SimulatorPool
import SynchronousWaiter
import TempFolder

public final class DistWorker {
    private let queueClient: SynchronousQueueClient
    private var onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>()
    private let syncQueue = DispatchQueue(label: "ru.avito.DistWorker")
    private var requestIdForBucketId = [String: String]()  // bucketId -> requestId
    
    public init(queueServerAddress: String, queueServerPort: Int, workerId: String) {
        queueClient = SynchronousQueueClient(
            serverAddress: queueServerAddress,
            serverPort: queueServerPort,
            workerId: workerId)
    }
    
    public func start() throws {
        let workerConfiguration = try queueClient.registerWithServer()
        log("Registered with server. Worker configuration: \(workerConfiguration)")
        _ = try runTests(workerConfiguration: workerConfiguration)
        log("Dist worker has finished")
        cleanUpAndStop()
    }
    
    // MARK: - Private Stuff
    
    private func runTests(workerConfiguration: WorkerConfiguration) throws -> [TestingResult] {
        let factory = BucketConfigurationFactory()
        let configuration = try factory.createConfiguration(
            workerConfiguration: workerConfiguration,
            schedulerDataSource: DistRunSchedulerDataSource(onNextBucketRequest: fetchNextBucket),
            onDemandSimulatorPool: onDemandSimulatorPool)
        let tempFolder = try factory.createTempFolder()
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: factory.pluginLocations,
            environment: configuration.testExecutionBehavior.environment)
        let scheduler = Scheduler(eventBus: eventBus, configuration: configuration, tempFolder: tempFolder)
        let eventStreamProcessor = EventStreamProcessor { [weak self] testingResult in
            self?.didReceiveTestResult(testingResult: testingResult)
        }
        eventBus.add(stream: eventStreamProcessor)
        return try scheduler.run()
    }
    
    private func cleanUpAndStop() {
        queueClient.close()
        log("Cleaning up the simulators")
        onDemandSimulatorPool.deleteSimulators()
    }
    
    // MARK: - Callbacks

    private func fetchNextBucket() -> Bucket? {
        while true {
            do {
                log("Fetching next bucket from server")
                let requestId = UUID().uuidString
                let result = try queueClient.fetchBucket(requestId: requestId)
                switch result {
                case .queueIsEmpty:
                    log("Server returned that queue is empty")
                    return nil
                case .workerHasBeenBlocked:
                    log("Server has blocked this worker")
                    return nil
                case .checkLater(let after):
                    log("Server asked to wait for \(after) seconds and fetch next bucket again")
                    SynchronousWaiter.wait(timeout: after)
                case .bucket(let fetchedBucket):
                    syncQueue.sync {
                        requestIdForBucketId[fetchedBucket.bucketId] = requestId
                    }
                    log("Received bucket \(fetchedBucket.bucketId), requestId: \(requestId)", color: .blue)
                    return fetchedBucket
                }
            } catch {
                log("Failed to fetch next bucket: \(error)")
                return nil
            }
        }
    }
    
    private func didReceiveTestResult(testingResult: TestingResult) {
        let bucketResult = BucketResult(testingResult: testingResult)
        do {
            let requestId: String = try syncQueue.sync {
                guard let requestId = requestIdForBucketId[testingResult.bucket.bucketId] else {
                    log("Error: no requestId for bucket: \(testingResult.bucket.bucketId)", color: .red)
                    throw DistWorkerError.noRequestIdForBucketId(testingResult.bucket.bucketId)
                }
                return requestId
            }
            try queueClient.send(bucketResult: bucketResult, requestId: requestId)
        } catch {
            log("Failed to send test run result for bucket \(testingResult.bucket.bucketId): \(error)")
            cleanUpAndStop()
        }
    }
}
