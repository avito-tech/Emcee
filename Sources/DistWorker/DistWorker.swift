import CurrentlyBeingProcessedBucketsTracker
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import PluginManager
import QueueClient
import ResourceLocationResolver
import Scheduler
import SimulatorPool
import SynchronousWaiter
import TempFolder
import Timer

public final class DistWorker {
    private let queueClient: SynchronousQueueClient
    private let syncQueue = DispatchQueue(label: "ru.avito.DistWorker")
    private var requestIdForBucketId = [String: String]()  // bucketId -> requestId
    private let bucketConfigurationFactory: BucketConfigurationFactory
    private let resourceLocationResolver: ResourceLocationResolver
    private var reportingAliveTimer: DispatchBasedTimer?
    private let currentlyBeingProcessedBucketsTracker = CurrentlyBeingProcessedBucketsTracker()
    
    public init(
        queueServerAddress: String,
        queueServerPort: Int,
        workerId: String,
        resourceLocationResolver: ResourceLocationResolver)
    {
        self.resourceLocationResolver = resourceLocationResolver
        self.bucketConfigurationFactory = BucketConfigurationFactory(resourceLocationResolver: resourceLocationResolver)
        self.queueClient = SynchronousQueueClient(
            serverAddress: queueServerAddress,
            serverPort: queueServerPort,
            workerId: workerId)
    }
    
    public func start() throws {
        let tempFolder = try bucketConfigurationFactory.createTempFolder()
        let workerConfiguration = try queueClient.registerWithServer()
        Logger.debug("Registered with server. Worker configuration: \(workerConfiguration)")
        startReportingWorkerIsAlive(interval: workerConfiguration.reportAliveInterval)
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        _ = try runTests(
            workerConfiguration: workerConfiguration,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder)
        Logger.verboseDebug("Dist worker has finished")
        cleanUpAndStop()
    }
    
    private func startReportingWorkerIsAlive(interval: TimeInterval) {
        reportingAliveTimer = DispatchBasedTimer.startedTimer(
            repeating: .milliseconds(Int(interval * 1000.0)),
            leeway: .seconds(1)) { [weak self] in
                guard let strongSelf = self else { return }
                do {
                    try strongSelf.reportAliveness()
                } catch {
                    Logger.error("Failed to report aliveness: \(error)")
                }
        }
    }
    
    private func reportAliveness() throws {
        try queueClient.reportAliveness {
            syncQueue.sync { currentlyBeingProcessedBucketsTracker.bucketIdsBeingProcessed }
        }
    }
    
    // MARK: - Private Stuff
    
    private func runTests(
        workerConfiguration: WorkerConfiguration,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        tempFolder: TempFolder)
        throws -> [TestingResult]
    {
        let configuration = bucketConfigurationFactory.createConfiguration(
            workerConfiguration: workerConfiguration,
            schedulerDataSource: DistRunSchedulerDataSource(onNextBucketRequest: fetchNextBucket),
            onDemandSimulatorPool: onDemandSimulatorPool)
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: bucketConfigurationFactory.pluginLocations,
            resourceLocationResolver: resourceLocationResolver,
            environment: configuration.testRunExecutionBehavior.environment)
        defer { eventBus.tearDown() }
        
        let scheduler = Scheduler(
            eventBus: eventBus,
            configuration: configuration,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
        let eventStreamProcessor = EventStreamProcessor { [weak self] testingResult in
            Logger.debug("Obtained testingResult: \(testingResult)")
            self?.didReceiveTestResult(testingResult: testingResult)
        }
        eventBus.add(stream: eventStreamProcessor)
        return try scheduler.run()
    }
    
    private func cleanUpAndStop() {
        queueClient.close()
        reportingAliveTimer?.stop()
    }
    
    // MARK: - Callbacks

    private func fetchNextBucket() -> SchedulerBucket? {
        while true {
            do {
                Logger.debug("Fetching next bucket from server")
                let requestId = UUID().uuidString
                let result = try queueClient.fetchBucket(requestId: requestId)
                switch result {
                case .queueIsEmpty:
                    Logger.debug("Server returned that queue is empty")
                    return nil
                case .workerHasBeenBlocked:
                    Logger.debug("Server has blocked this worker")
                    return nil
                case .checkLater(let after):
                    Logger.debug("Server asked to wait for \(after) seconds and fetch next bucket again")
                    SynchronousWaiter.wait(timeout: after)
                case .bucket(let fetchedBucket):
                    syncQueue.sync {
                        requestIdForBucketId[fetchedBucket.bucketId] = requestId
                        currentlyBeingProcessedBucketsTracker.didFetch(bucketId: fetchedBucket.bucketId)
                    }
                    Logger.debug("Received bucket \(fetchedBucket.bucketId), requestId: \(requestId)")
                    return SchedulerBucket.from(bucket: fetchedBucket)
                }
            } catch {
                Logger.error("Failed to fetch next bucket: \(error)")
                return nil
            }
        }
    }
    
    private func didReceiveTestResult(testingResult: TestingResult) {
        do {
            let requestId: String = try syncQueue.sync {
                guard let requestId = requestIdForBucketId[testingResult.bucketId] else {
                    Logger.error("No requestId for bucket: \(testingResult.bucketId)")
                    throw DistWorkerError.noRequestIdForBucketId(testingResult.bucketId)
                }
                return requestId
            }
            let acceptedBucketId = try queueClient.send(testingResult: testingResult, requestId: requestId)
            if acceptedBucketId != testingResult.bucketId {
                throw DistWorkerError.unexpectedAcceptedBucketId(actual: acceptedBucketId, expected: testingResult.bucketId)
            }
        } catch {
            Logger.error("Failed to send test run result for bucket \(testingResult.bucketId): \(error)")
            cleanUpAndStop()
        }
        
        syncQueue.sync {
            requestIdForBucketId.removeValue(forKey: testingResult.bucketId)
            currentlyBeingProcessedBucketsTracker.didObtainResult(bucketId: testingResult.bucketId)
        }
    }
}
