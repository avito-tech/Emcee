import AutomaticTermination
import DateProvider
import DeveloperDirLocator
import Dispatch
import DistWorkerModels
import EventBus
import Foundation
import FileSystem
import LocalHostDeterminer
import Logging
import LoggingSetup
import Models
import PathLib
import PluginManager
import QueueClient
import RESTMethods
import RESTServer
import RequestSender
import ResourceLocationResolver
import Runner
import Scheduler
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import Timer

public final class DistWorker: SchedulerDelegate {
    private let bucketResultSender: BucketResultSender
    private let callbackQueue = DispatchQueue(label: "DistWorker.callbackQueue", qos: .default, attributes: .concurrent)
    private let currentlyBeingProcessedBucketsTracker = DefaultCurrentlyBeingProcessedBucketsTracker()
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let httpRestServer: HTTPRESTServer
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let queueClient: SynchronousQueueClient
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorSettingsModifier: SimulatorSettingsModifier
    private let syncQueue = DispatchQueue(label: "DistWorker.syncQueue")
    private let temporaryFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let version: Version
    private let workerId: WorkerId
    private let workerRegisterer: WorkerRegisterer
    private var payloadSignature = Either<PayloadSignature, DistWorkerError>.error(DistWorkerError.missingPayloadSignature)
    private var requestIdForBucketId = [BucketId: RequestId]()
    
    private enum BucketFetchResult: Equatable {
        case result(SchedulerBucket?)
        case checkAgain(after: TimeInterval)
    }
    
    public init(
        bucketResultSender: BucketResultSender,
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        queueClient: SynchronousQueueClient,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorSettingsModifier: SimulatorSettingsModifier,
        temporaryFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        version: Version,
        workerId: WorkerId,
        workerRegisterer: WorkerRegisterer
    ) {
        self.bucketResultSender = bucketResultSender
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.queueClient = queueClient
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorSettingsModifier = simulatorSettingsModifier
        self.temporaryFolder = temporaryFolder
        self.testRunnerProvider = testRunnerProvider
        self.version = version
        self.workerId = workerId
        self.workerRegisterer = workerRegisterer
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: StayAliveTerminationController(),
            portProvider: PortProviderWrapper(provider: { 0 })
        )
    }
    
    public func start(
        didFetchAnalyticsConfiguration: @escaping (AnalyticsConfiguration) throws -> (),
        completion: @escaping () -> ()
    ) throws {
        httpRestServer.add(
            handler: RESTEndpointOf(
                CurrentlyProcessingBucketsEndpoint(
                    currentlyBeingProcessedBucketsTracker: currentlyBeingProcessedBucketsTracker
                )
            )
        )

        workerRegisterer.registerWithServer(
            workerId: workerId,
            workerRestAddress: SocketAddress(
                host: LocalHostDeterminer.currentHostAddress,
                port: try httpRestServer.start()
            ),
            callbackQueue: callbackQueue
        ) { [weak self] result in
            do {
                guard let strongSelf = self else {
                    Logger.error("self is nil in start() in DistWorker")
                    completion()
                    return
                }
                
                let workerConfiguration = try result.dematerialize()
                
                strongSelf.payloadSignature = .success(workerConfiguration.payloadSignature)
                Logger.debug("Registered with server. Worker configuration: \(workerConfiguration)")
                
                try didFetchAnalyticsConfiguration(workerConfiguration.analyticsConfiguration)
                
                _ = try strongSelf.runTests(
                    workerConfiguration: workerConfiguration,
                    onDemandSimulatorPool: strongSelf.onDemandSimulatorPool
                )
                Logger.verboseDebug("Dist worker has finished")
                strongSelf.cleanUpAndStop()
                
                completion()
            } catch {
                Logger.error("Caught unexpected error: \(error)")
                completion()
            }
        }
    }
    
    // MARK: - Private Stuff
    
    private func runTests(
        workerConfiguration: WorkerConfiguration,
        onDemandSimulatorPool: OnDemandSimulatorPool
    ) throws {
        let schedulerCconfiguration = SchedulerConfiguration(
            numberOfSimulators: workerConfiguration.numberOfSimulators,
            onDemandSimulatorPool: onDemandSimulatorPool,
            schedulerDataSource: DistRunSchedulerDataSource(
                onNextBucketRequest: fetchNextBucket
            )
        )
        
        let scheduler = Scheduler(
            configuration: schedulerCconfiguration,
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            schedulerDelegate: self,
            simulatorSettingsModifier: simulatorSettingsModifier,
            tempFolder: temporaryFolder,
            testRunnerProvider: testRunnerProvider,
            version: version
        )
        try scheduler.run()
    }
    
    public func cleanUpAndStop() {
        queueClient.close()
    }
    
    // MARK: - Callbacks
    
    private func nextBucketFetchResult() throws -> BucketFetchResult {
        return try currentlyBeingProcessedBucketsTracker.perform { tracker -> BucketFetchResult in
            let requestId = RequestId(value: UUID().uuidString)
            let result = try queueClient.fetchBucket(
                requestId: requestId,
                workerId: workerId,
                payloadSignature: try payloadSignature.dematerialize()
            )
            switch result {
            case .queueIsEmpty:
                Logger.debug("Server returned that queue is empty")
                return .result(nil)
            case .workerNotRegistered:
                Logger.error("Server considers this worker as not registered")
                return .result(nil)
            case .checkLater(let after):
                Logger.debug("Server asked to wait for \(after) seconds and fetch next bucket again")
                return .checkAgain(after: after)
            case .bucket(let fetchedBucket):
                Logger.debug("Received \(fetchedBucket.bucketId) for \(requestId)")
                tracker.willProcess(bucketId: fetchedBucket.bucketId)
                syncQueue.sync {
                    requestIdForBucketId[fetchedBucket.bucketId] = requestId
                }
                return .result(
                    SchedulerBucket.from(
                        bucket: fetchedBucket,
                        testExecutionBehavior: TestExecutionBehavior(
                            environment: fetchedBucket.testExecutionBehavior.environment,
                            numberOfRetries: 0
                        )
                    )
                )
            }
        }
    }
    
    private func fetchNextBucket() -> SchedulerBucket? {
        while true {
            do {
                Logger.debug("Fetching next bucket from server")
                let fetchResult = try nextBucketFetchResult()
                switch fetchResult {
                case .result(let result):
                    return result
                case .checkAgain(let after):
                    SynchronousWaiter().wait(timeout: after, description: "Pause before checking queue server again")
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
    ) {
        Logger.debug("Obtained testing result for bucket \(bucket): \(testingResult)")
        didReceiveTestResult(testingResult: testingResult)
    }
    
    private func didReceiveTestResult(testingResult: TestingResult) {
        do {
            let requestId: RequestId = try syncQueue.sync {
                guard let requestId = requestIdForBucketId.removeValue(forKey: testingResult.bucketId) else {
                    Logger.error("No requestId for bucket: \(testingResult.bucketId)")
                    throw DistWorkerError.noRequestIdForBucketId(testingResult.bucketId)
                }
                Logger.verboseDebug("Found \(requestId) for bucket \(testingResult.bucketId)")
                return requestId
            }
            
            bucketResultSender.send(
                testingResult: testingResult,
                requestId: requestId,
                workerId: workerId,
                payloadSignature: try payloadSignature.dematerialize(),
                callbackQueue: callbackQueue,
                completion: { [currentlyBeingProcessedBucketsTracker] (result: Either<BucketId, Error>) in
                    defer {
                        currentlyBeingProcessedBucketsTracker.didProcess(bucketId: testingResult.bucketId)
                    }
                    
                    do {
                        let acceptedBucketId = try result.dematerialize()
                        guard testingResult.bucketId == acceptedBucketId else {
                            throw DistWorkerError.unexpectedAcceptedBucketId(
                                actual: acceptedBucketId,
                                expected: testingResult.bucketId
                            )
                        }
                        Logger.debug("Successfully sent test run result for bucket \(testingResult.bucketId)")
                    } catch {
                        Logger.error("Server response for results of bucket \(testingResult.bucketId) has error: \(error)")
                    }
                }
            )
        } catch {
            Logger.error("Failed to send test run result for bucket \(testingResult.bucketId): \(error)")
            cleanUpAndStop()
        }
    }
}
