import AtomicModels
import AutomaticTermination
import DI
import DateProvider
import DeveloperDirLocator
import Dispatch
import DistWorkerModels
import EmceeLogging
import EventBus
import FileSystem
import Foundation
import LocalHostDeterminer
import Metrics
import MetricsExtensions
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
import Tmp
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
    private let logger = ContextualLogger(DistWorker.self)
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
            defer {
                completion()
            }
            guard let strongSelf = self else { return }
            do {
                let workerConfiguration = try result.dematerialize()
                
                try strongSelf.di.get(GlobalMetricRecorder.self).set(
                    analyticsConfiguration: workerConfiguration.globalAnalyticsConfiguration
                )
                
                strongSelf.payloadSignature = .success(workerConfiguration.payloadSignature)
                strongSelf.logger.log(.debug, "Registered with server. Worker configuration: \(workerConfiguration)", workerId: strongSelf.workerId)
                
                _ = try strongSelf.runTests(
                    workerConfiguration: workerConfiguration
                )
                strongSelf.logger.log(.debug, "Dist worker has finished", workerId: strongSelf.workerId)
            } catch {
                strongSelf.logger.log(.error, "Caught unexpected error: \(error)", workerId: strongSelf.workerId)
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
            let callbackWaiter: CallbackWaiter<Either<BucketFetchResult, Error>> = try di.get(Waiter.self).createCallbackWaiter()
            
            try di.get(BucketFetcher.self).fetch(
                payloadSignature: try payloadSignature.dematerialize(),
                workerCapabilities: try di.get(WorkerCapabilitiesProvider.self).workerCapabilities(),
                workerId: workerId,
                callbackQueue: callbackQueue
            ) { response in callbackWaiter.set(result: response) }
            
            let result = try callbackWaiter.wait(timeout: .infinity, description: "Fetch next bucket").dematerialize()

            switch result {
            case .checkLater(let after):
                logger.log(.debug, "Server asked to wait for \(after) seconds and fetch next bucket again", workerId: workerId)
                return .checkAgain(after: after)
            case .bucket(let fetchedBucket):
                logger.log(.debug, "Received \(fetchedBucket.bucketId)", workerId: workerId)
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
                logger.log(.debug, "Fetching next bucket from server", workerId: workerId)
                let fetchResult = try nextBucketFetchResult()
                switch fetchResult {
                case .result(let result):
                    return result
                case .checkAgain(let after):
                    try di.get(Waiter.self).wait(timeout: after, description: "Pause before checking queue server again")
                }
            } catch {
                logger.log(.error, "Failed to fetch next bucket: \(error)", workerId: workerId)
                return nil
            }
        }
    }
    
    public func scheduler(
        _ sender: Scheduler,
        obtainedTestingResult testingResult: TestingResult,
        forBucket bucket: SchedulerBucket
    ) {
        logger.log(.debug, "Obtained testing result for bucket \(bucket.bucketId): \(testingResult)", workerId: workerId)
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
                completion: { [currentlyBeingProcessedBucketsTracker, logger, workerId] (result: Either<BucketId, Error>) in
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
                        logger.log(.debug, "Successfully sent test run result for bucket \(bucketId)", workerId: workerId)
                    } catch {
                        logger.log(.error, "Server response for results of bucket \(bucketId) has error: \(error)", workerId: workerId)
                    }
                }
            )
        } catch {
            logger.log(.error, "Failed to send test run result for bucket \(bucketId): \(error)", workerId: workerId)
        }
    }
}
