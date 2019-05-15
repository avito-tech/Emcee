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

public final class DistWorker: SchedulerDelegate {
    private let queueClient: SynchronousQueueClient
    private let syncQueue = DispatchQueue(label: "ru.avito.DistWorker")
    private var requestIdForBucketId = [String: String]()  // bucketId -> requestId
    private let bucketConfigurationFactory: BucketConfigurationFactory
    private let resourceLocationResolver: ResourceLocationResolver
    private var reportingAliveTimer: DispatchBasedTimer?
    private let currentlyBeingProcessedBucketsTracker = CurrentlyBeingProcessedBucketsTracker()
    private let workerId: String
    
    public init(
        queueServerAddress: SocketAddress,
        workerId: String,
        resourceLocationResolver: ResourceLocationResolver)
    {
        self.resourceLocationResolver = resourceLocationResolver
        self.bucketConfigurationFactory = BucketConfigurationFactory(
            resourceLocationResolver: resourceLocationResolver
        )
        self.queueClient = SynchronousQueueClient(queueServerAddress: queueServerAddress)
        self.workerId = workerId
    }
    
    public func start() throws {
        let tempFolder = try bucketConfigurationFactory.createTempFolder()
        let workerConfiguration = try queueClient.registerWithServer(workerId: workerId)
        Logger.debug("Registered with server. Worker configuration: \(workerConfiguration)")
        startReportingWorkerIsAlive(interval: workerConfiguration.reportAliveInterval)
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        _ = try runTests(
            workerConfiguration: workerConfiguration,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder
        )
        Logger.verboseDebug("Dist worker has finished")
        cleanUpAndStop()
    }
    
    private func startReportingWorkerIsAlive(interval: TimeInterval) {
        reportingAliveTimer = DispatchBasedTimer.startedTimer(
            repeating: .milliseconds(Int(interval * 1000.0)),
            leeway: .seconds(1)) { [weak self] _ in
                guard let strongSelf = self else { return }
                do {
                    try strongSelf.reportAliveness()
                } catch {
                    Logger.error("Failed to report aliveness: \(error)")
                }
        }
    }
    
    private func reportAliveness() throws {
        try queueClient.reportAliveness(
            bucketIdsBeingProcessedProvider: {
                currentlyBeingProcessedBucketsTracker.bucketIdsBeingProcessed
            },
            workerId: workerId
        )
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
            pluginLocations: bucketConfigurationFactory.pluginLocations + workerConfiguration.pluginUrls.map {
                PluginLocation(ResourceLocation.remoteUrl($0))
            },
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let scheduler = Scheduler(
            eventBus: eventBus,
            configuration: configuration,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver,
            schedulerDelegate: self
        )
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
                let result = try queueClient.fetchBucket(requestId: requestId, workerId: workerId)
                switch result {
                case .queueIsEmpty:
                    Logger.debug("Server returned that queue is empty")
                    return nil
                case .workerHasBeenBlocked:
                    Logger.error("Server has blocked this worker")
                    return nil
                case .workerConsideredNotAlive:
                    Logger.error("Server considers this worker as not alive")
                    return nil
                case .checkLater(let after):
                    Logger.debug("Server asked to wait for \(after) seconds and fetch next bucket again")
                    SynchronousWaiter.wait(timeout: after)
                case .bucket(let fetchedBucket):
                    Logger.debug("Received bucket \(fetchedBucket.bucketId), requestId: \(requestId)")
                    currentlyBeingProcessedBucketsTracker.didFetch(bucketId: fetchedBucket.bucketId)
                    syncQueue.sync {
                        requestIdForBucketId[fetchedBucket.bucketId] = requestId
                    }
                    return SchedulerBucket.from(bucket: fetchedBucket)
                }
            } catch {
                Logger.error("Failed to fetch next bucket: \(error)")
                return nil
            }
        }
    }
    
    public func scheduler(
        _ sender: Scheduler,
        obtainedTestingResult testingResult: TestingResult,
        forBucket bucket: SchedulerBucket
        )
    {
        Logger.debug("Obtained testingResult: \(testingResult)")
        didReceiveTestResult(testingResult: testingResult)
    }
    
    private func didReceiveTestResult(testingResult: TestingResult) {
        defer {
            currentlyBeingProcessedBucketsTracker.didObtainResult(bucketId: testingResult.bucketId)
        }
        
        do {
            let requestId: String = try syncQueue.sync {
                guard let requestId = requestIdForBucketId.removeValue(forKey: testingResult.bucketId) else {
                    Logger.error("No requestId for bucket: \(testingResult.bucketId)")
                    throw DistWorkerError.noRequestIdForBucketId(testingResult.bucketId)
                }
                Logger.verboseDebug("Found requestId for bucket: \(testingResult.bucketId): \(requestId)")
                return requestId
            }
            let acceptedBucketId = try queueClient.send(
                testingResult: testingResult,
                requestId: requestId,
                workerId: workerId
            )
            guard acceptedBucketId == testingResult.bucketId else {
                throw DistWorkerError.unexpectedAcceptedBucketId(
                    actual: acceptedBucketId,
                    expected: testingResult.bucketId
                )
            }
            Logger.debug("Successfully sent test run result for bucket \(testingResult.bucketId)")
        } catch {
            Logger.error("Failed to send test run result for bucket \(testingResult.bucketId): \(error)")
            cleanUpAndStop()
        }
    }
}
