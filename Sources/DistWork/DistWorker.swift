import Dispatch
import EventBus
import Foundation
import Logging
import Models
import PluginManager
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
        log("Registered with server. Worker configuration: \(workerConfiguration)")
        startReportingWorkerIsAlive(interval: workerConfiguration.reportAliveInterval)
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        _ = try runTests(
            workerConfiguration: workerConfiguration,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder)
        log("Dist worker has finished")
        cleanUpAndStop()
    }
    
    private func startReportingWorkerIsAlive(interval: TimeInterval) {
        reportingAliveTimer = DispatchBasedTimer.startedTimer(
            repeating: .milliseconds(Int(interval * 1000.0)),
            leeway: .seconds(1)) { [weak queueClient] in
                if let client = queueClient {
                    do {
                        try client.reportAliveness()
                    } catch {
                        log("Error: failed to report aliveness: \(error)")
                    }
                }
        }
    }
    
    // MARK: - Private Stuff
    
    private func runTests(
        workerConfiguration: WorkerConfiguration,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        tempFolder: TempFolder)
        throws -> [TestingResult]
    {
        let configuration = try bucketConfigurationFactory.createConfiguration(
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
                    return schedulerBucketByOverridingToolResourcesWithLocalIfNeeded(fetchedBucket)
                }
            } catch {
                log("Failed to fetch next bucket: \(error)")
                return nil
            }
        }
    }
    
    private func schedulerBucketByOverridingToolResourcesWithLocalIfNeeded(_ bucket: Bucket) -> SchedulerBucket {
        let fbsimctl = bucketConfigurationFactory.fbsimctl ?? bucket.toolResources.fbsimctl
        let fbxctest = bucketConfigurationFactory.fbxctest ?? bucket.toolResources.fbxctest
        
        let additionalApps = bucketConfigurationFactory.locallyDeployedAdditionalApps + bucket.buildArtifacts.additionalApplicationBundles.compactMap {
            switch $0.resourceLocation {
            case .remoteUrl:
                return $0
            case .localFilePath(let path):
                return FileManager.default.fileExists(atPath: path) ? $0 : nil
            }
        }
        let appBundle = bucketConfigurationFactory.appBundle ?? bucket.buildArtifacts.appBundle
        let runner = bucketConfigurationFactory.runner ?? bucket.buildArtifacts.runner
        let xcTestBundle = bucketConfigurationFactory.xcTestBundle ?? bucket.buildArtifacts.xcTestBundle
        
        return SchedulerBucket(
            bucketId: bucket.bucketId,
            testEntries: bucket.testEntries,
            testDestination: bucket.testDestination,
            toolResources: ToolResources(fbsimctl: fbsimctl, fbxctest: fbxctest),
            buildArtifacts: BuildArtifacts(appBundle: appBundle, runner: runner, xcTestBundle: xcTestBundle, additionalApplicationBundles: additionalApps))
    }
    
    private func didReceiveTestResult(testingResult: TestingResult) {
        do {
            let requestId: String = try syncQueue.sync {
                guard let requestId = requestIdForBucketId[testingResult.bucketId] else {
                    log("Error: no requestId for bucket: \(testingResult.bucketId)", color: .red)
                    throw DistWorkerError.noRequestIdForBucketId(testingResult.bucketId)
                }
                return requestId
            }
            try queueClient.send(testingResult: testingResult, requestId: requestId)
        } catch {
            log("Failed to send test run result for bucket \(testingResult.bucketId): \(error)")
            cleanUpAndStop()
        }
    }
}
