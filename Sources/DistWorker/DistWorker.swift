import AtomicModels
import AutomaticTermination
import DI
import DateProvider
import DeveloperDirLocator
import Dispatch
import DistWorkerModels
import EventBus
import FileSystem
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import PathLib
import PluginManager
import QueueClient
import QueueModels
import RESTMethods
import RESTServer
import RequestSender
import ResourceLocationResolver
import Runner
import RunnerModels
import Scheduler
import SimulatorPool
import SocketModels
import SynchronousWaiter
import TemporaryStuff
import Timer
import Types
import UniqueIdentifierGenerator
import WorkerCapabilities

public final class DistWorker: SchedulerDataSource, SchedulerDelegate {
    private let di: DI
    private let callbackQueue = DispatchQueue(label: "DistWorker.callbackQueue", qos: .default, attributes: .concurrent)
    private let currentlyBeingProcessedBucketsTracker = DefaultCurrentlyBeingProcessedBucketsTracker()
    private let httpRestServer: HTTPRESTServer
    private let version: Version
    private let workerId: WorkerId
    private var payloadSignature = Either<PayloadSignature, DistWorkerError>.error(DistWorkerError.missingPayloadSignature)
    
    private enum ReducedBucketFetchResult: Equatable {
        case result(SchedulerBucket?)
        case checkAgain(after: TimeInterval)
    }
    
    public init(
        di: DI,
        version: Version,
        workerId: WorkerId
    ) {
        self.di = di
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: StayAliveTerminationController(),
            portProvider: PortProviderWrapper(provider: { 0 })
        )
        self.version = version
        self.workerId = workerId
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

        try di.get(WorkerRegisterer.self).registerWithServer(
            workerId: workerId,
            workerCapabilities: try di.get(WorkerCapabilitiesProvider.self).workerCapabilities(),
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
                    workerConfiguration: workerConfiguration
                )
                Logger.verboseDebug("Dist worker has finished")
                
                completion()
            } catch {
                Logger.error("Caught unexpected error: \(error)")
                completion()
            }
        }
    }
    
    // MARK: - Private Stuff
    
    private func runTests(
        workerConfiguration: WorkerConfiguration
    ) throws {
        let scheduler = Scheduler(
            di: di,
            numberOfSimulators: workerConfiguration.numberOfSimulators,
            schedulerDataSource: self,
            schedulerDelegate: self,
            version: version
        )
        try scheduler.run()
    }
    
    // MARK: - Callbacks
    
    private func nextBucketFetchResult() throws -> ReducedBucketFetchResult {
        return try currentlyBeingProcessedBucketsTracker.perform { tracker -> ReducedBucketFetchResult in
            let waiter = SynchronousWaiter()
            
            let callbackWaiter: CallbackWaiter<Either<BucketFetchResult, Error>> = waiter.createCallbackWaiter()
            
            try di.get(BucketFetcher.self).fetch(
                payloadSignature: try payloadSignature.dematerialize(),
                workerCapabilities: try di.get(WorkerCapabilitiesProvider.self).workerCapabilities(),
                workerId: workerId,
                callbackQueue: callbackQueue
            ) { response in callbackWaiter.set(result: response) }
            
            let result = try callbackWaiter.wait(timeout: .infinity, description: "Fetch next bucket").dematerialize()

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
                Logger.debug("Received \(fetchedBucket.bucketId)")
                tracker.willProcess(bucketId: fetchedBucket.bucketId)
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
    
    public func nextBucket() -> SchedulerBucket? {
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
        Logger.debug("Obtained testing result for bucket \(bucket.bucketId): \(testingResult)")
        didReceiveTestResult(testingResult: testingResult, bucketId: bucket.bucketId)
    }
    
    private func didReceiveTestResult(testingResult: TestingResult, bucketId: BucketId) {
        do {
            try di.get(BucketResultSender.self).send(
                bucketId: bucketId,
                testingResult: testingResult,
                workerId: workerId,
                payloadSignature: try payloadSignature.dematerialize(),
                callbackQueue: callbackQueue,
                completion: { [currentlyBeingProcessedBucketsTracker] (result: Either<BucketId, Error>) in
                    defer {
                        currentlyBeingProcessedBucketsTracker.didProcess(bucketId: bucketId)
                    }
                    
                    do {
                        let acceptedBucketId = try result.dematerialize()
                        guard bucketId == acceptedBucketId else {
                            throw DistWorkerError.unexpectedAcceptedBucketId(
                                actual: acceptedBucketId,
                                expected: bucketId
                            )
                        }
                        Logger.debug("Successfully sent test run result for bucket \(bucketId)")
                    } catch {
                        Logger.error("Server response for results of bucket \(bucketId) has error: \(error)")
                    }
                }
            )
        } catch {
            Logger.error("Failed to send test run result for bucket \(bucketId): \(error)")
        }
    }
}
