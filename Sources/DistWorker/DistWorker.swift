import CurrentlyBeingProcessedBucketsTracker
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import PathLib
import PluginManager
import QueueClient
import RequestSender
import ResourceLocationResolver
import Runner
import Scheduler
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import RESTMethods
import Timer


public final class DistWorker: SchedulerDelegate {
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let queueClient: SynchronousQueueClient
    private let syncQueue = DispatchQueue(label: "DistWorker.syncQueue")
    private let callbackQueue = DispatchQueue(label: "DistWorker.callbackQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    private var requestIdForBucketId = [BucketId: RequestId]()
    private let resourceLocationResolver: ResourceLocationResolver
    private var reportingAliveTimer: DispatchBasedTimer?
    private let currentlyBeingProcessedBucketsTracker = CurrentlyBeingProcessedBucketsTracker()
    private let workerId: WorkerId
    private var requestSignature = Either<RequestSignature, DistWorkerError>.error(DistWorkerError.missingRequestSignature)
    private let temporaryFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let workerRegisterer: WorkerRegisterer
    private let reportAliveSender: ReportAliveSender
    private let bucketResultSender: BucketResultSender
    
    private enum BucketFetchResult: Equatable {
        case result(SchedulerBucket?)
        case checkAgain(after: TimeInterval)
    }
    
    public init(
        onDemandSimulatorPool: OnDemandSimulatorPool,
        queueClient: SynchronousQueueClient,
        workerId: WorkerId,
        resourceLocationResolver: ResourceLocationResolver,
        temporaryFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        reportAliveSender: ReportAliveSender,
        workerRegisterer: WorkerRegisterer,
        bucketResultSender: BucketResultSender
    ) {
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.queueClient = queueClient
        self.workerId = workerId
        self.resourceLocationResolver = resourceLocationResolver
        self.temporaryFolder = temporaryFolder
        self.testRunnerProvider = testRunnerProvider
        self.reportAliveSender = reportAliveSender
        self.workerRegisterer = workerRegisterer
        self.bucketResultSender = bucketResultSender
    }
    
    public func start(
        didFetchAnalyticsConfiguration: @escaping (AnalyticsConfiguration) throws -> (),
        completion: @escaping () -> ()
    ) throws {
        workerRegisterer.registerWithServer(
            workerId: workerId,
            callbackQueue: callbackQueue
        ) { [weak self] result in
            do {
                guard let strongSelf = self else {
                    Logger.error("self is nil in start() in DistWorker")
                    completion()
                    return
                }
                
                let workerConfiguration = try result.dematerialize()
                
                strongSelf.requestSignature = .success(workerConfiguration.requestSignature)
                Logger.debug("Registered with server. Worker configuration: \(workerConfiguration)")
                
                try didFetchAnalyticsConfiguration(workerConfiguration.analyticsConfiguration)
                
                strongSelf.startReportingWorkerIsAlive(interval: workerConfiguration.reportAliveInterval)
                
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
        reportAliveSender.reportAlive(
            bucketIdsBeingProcessedProvider: currentlyBeingProcessedBucketsTracker.bucketIdsBeingProcessed,
            workerId: workerId,
            requestSignature: try requestSignature.dematerialize(),
            callbackQueue: callbackQueue
        ) { (result: Either<ReportAliveResponse, Error>) in
            do {
                _ = try result.dematerialize()
            } catch {
                Logger.error("Report aliveness error: \(error)")
            }
        }
    }
    
    // MARK: - Private Stuff
    
    private func runTests(
        workerConfiguration: WorkerConfiguration,
        onDemandSimulatorPool: OnDemandSimulatorPool
    ) throws -> [TestingResult] {
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: workerConfiguration.pluginUrls.map {
                PluginLocation(ResourceLocation.remoteUrl($0))
            },
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let schedulerCconfiguration = SchedulerConfiguration(
            testRunExecutionBehavior: workerConfiguration.testRunExecutionBehavior,
            testTimeoutConfiguration: workerConfiguration.testTimeoutConfiguration,
            schedulerDataSource: DistRunSchedulerDataSource(onNextBucketRequest: fetchNextBucket),
            onDemandSimulatorPool: onDemandSimulatorPool
        )
        
        let scheduler = Scheduler(
            eventBus: eventBus,
            configuration: schedulerCconfiguration,
            tempFolder: temporaryFolder,
            resourceLocationResolver: resourceLocationResolver,
            schedulerDelegate: self,
            testRunnerProvider: testRunnerProvider
        )
        return try scheduler.run()
    }
    
    private func cleanUpAndStop() {
        queueClient.close()
        reportingAliveTimer?.stop()
    }
    
    // MARK: - Callbacks
    
    private func nextBucketFetchResult() throws -> BucketFetchResult {
        reportingAliveTimer?.pause()
        defer { reportingAliveTimer?.resume() }
        
        let requestId = RequestId(value: UUID().uuidString)
        let result = try queueClient.fetchBucket(
            requestId: requestId,
            workerId: workerId,
            requestSignature: try requestSignature.dematerialize()
        )
        switch result {
        case .queueIsEmpty:
            Logger.debug("Server returned that queue is empty")
            return .result(nil)
        case .workerHasBeenBlocked:
            Logger.error("Server has blocked this worker")
            return .result(nil)
        case .workerConsideredNotAlive:
            Logger.error("Server considers this worker as not alive")
            return .result(nil)
        case .checkLater(let after):
            Logger.debug("Server asked to wait for \(after) seconds and fetch next bucket again")
            return .checkAgain(after: after)
        case .bucket(let fetchedBucket):
            Logger.debug("Received \(fetchedBucket.bucketId) for \(requestId)")
            currentlyBeingProcessedBucketsTracker.didFetch(bucketId: fetchedBucket.bucketId)
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
    
    private func fetchNextBucket() -> SchedulerBucket? {
        while true {
            do {
                Logger.debug("Fetching next bucket from server")
                let fetchResult = try nextBucketFetchResult()
                switch fetchResult {
                case .result(let result):
                    return result
                case .checkAgain(let after):
                    SynchronousWaiter.wait(timeout: after, description: "Pause before checking queue server again")
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
        Logger.debug("Obtained testingResult: \(testingResult)")
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
                requestSignature: try requestSignature.dematerialize(),
                callbackQueue: callbackQueue,
                completion: { [currentlyBeingProcessedBucketsTracker] (result: Either<BucketId, Error>) in
                    defer {
                        currentlyBeingProcessedBucketsTracker.didObtainResult(bucketId: testingResult.bucketId)
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
