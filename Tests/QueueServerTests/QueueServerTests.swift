import AutomaticTermination
import DateProviderTestHelpers
import DistWorkerModels
import DistWorkerModelsTestHelpers
import EmceeLogging
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import PortDeterminer
import QueueClient
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RemotePortDeterminerTestHelpers
import RequestSender
import RequestSenderTestHelpers
import RunnerTestHelpers
import ScheduleStrategy
import SocketModels
import TestHelpers
import Types
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import XCTest

final class QueueServerTests: XCTestCase {
    private let workerConfigurations = WorkerConfigurations()
    private let workerId: WorkerId = "workerId"
    private let jobId: JobId = "jobId"
    private lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: jobId,
        jobPriority: .medium
    )
    private let automaticTerminationController = AutomaticTerminationControllerFactory(
        automaticTerminationPolicy: .stayAlive
    ).createAutomaticTerminationController()
    /// https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?&page=1
    private let localPortDeterminer = LocalPortDeterminer(
        logger: .noOp,
        portRange: 49152...65535
    )
    private let bucketSplitInfo = BucketSplitInfo(numberOfWorkers: 1)
    private let payloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    private lazy var workerAlivenessProvider: WorkerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: workerConfigurations.workerIds,
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    private lazy var workerCapabilitiesStorage: WorkerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    private let fixedBucketId: BucketId = "fixedBucketId"
    private lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
        value: fixedBucketId.value
    )
    private let callbackQueue = DispatchQueue(label: "callbackQueue")

    func test__queue_waits_for_new_workers_and_fails_if_they_not_appear_in_time() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        
        let server = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            bucketSplitInfo: bucketSplitInfo,
            checkAgainTimeInterval: .infinity,
            dateProvider: DateProviderFixture(),
            deploymentDestinations: [],
            emceeVersion: "emceeVersion",
            localPortDeterminer: localPortDeterminer,
            logger: .noOp,
            globalMetricRecorder: GlobalMetricRecorderImpl(),
            specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider(),
            onDemandWorkerStarter: FakeOnDemandWorkerStarter(),
            payloadSignature: payloadSignature,
            queueServerLock: NeverLockableQueueServerLock(),
            requestSenderProvider: DefaultRequestSenderProvider(logger: .noOp),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage,
            workerConfigurations: workerConfigurations,
            autoupdatingWorkerPermissionProvider: FakeAutoupdatingWorkerPermissionProvider(),
            workersToUtilizeService: FakeWorkersToUtilizeService()
        )
        XCTAssertThrowsError(try server.queueResults(jobId: jobId))
    }
    
    func test__queue_returns_results_after_depletion() throws {
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(
            bucketId: fixedBucketId,
            testEntries: [testEntry]
        )
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: testEntry)
            .testEntryConfigurations()
        let testingResult = TestingResultFixtures()
            .with(testEntry: testEntry)
            .addingLostResult()
            .testingResult()
        
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerCapabilitiesStorage.set(workerCapabilities: [], forWorkerId: workerId)
        
        let terminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: .afterBeingIdle(period: 0.1)
        ).createAutomaticTerminationController()
        let server = QueueServerImpl(
            automaticTerminationController: terminationController,
            bucketSplitInfo: bucketSplitInfo,
            checkAgainTimeInterval: .infinity,
            dateProvider: DateProviderFixture(),
            deploymentDestinations: [],
            emceeVersion: "emceeVersion",
            localPortDeterminer: localPortDeterminer,
            logger: .noOp,
            globalMetricRecorder: GlobalMetricRecorderImpl(),
            specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider(),
            onDemandWorkerStarter: FakeOnDemandWorkerStarter(),
            payloadSignature: payloadSignature,
            queueServerLock: NeverLockableQueueServerLock(),
            requestSenderProvider: DefaultRequestSenderProvider(logger: .noOp),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage,
            workerConfigurations: workerConfigurations,
            autoupdatingWorkerPermissionProvider: FakeAutoupdatingWorkerPermissionProvider(),
            workersToUtilizeService: FakeWorkersToUtilizeService()
        )
        try server.schedule(
            bucketSplitter: ScheduleStrategyType.individual.bucketSplitter(
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            ),
            testEntryConfigurations: testEntryConfigurations,
            prioritizedJob: prioritizedJob
        )
        let queueWaiter = QueueServerTerminationWaiterImpl(
            logger: .noOp,
            pollInterval: 0.1,
            queueServerTerminationPolicy: .stayAlive
        )
        
        let expectationForResults = expectation(description: "results became available")
        
        let port = try server.start()
        
        let requestSender = RequestSenderFixtures.localhostRequestSender(port: port)
        
        let workerRegisterer = WorkerRegistererImpl(requestSender: requestSender)
        
        var actualResults = [JobResults]()
        
        _ = try runSyncronously { [callbackQueue, workerId] completion in
            workerRegisterer.registerWithServer(
                workerId: workerId,
                workerCapabilities: [],
                workerRestAddress: SocketAddress(host: "host", port: 0),
                callbackQueue: callbackQueue
            ) { _ in
                completion(Void())
            }
        }
        
        DispatchQueue.global().async {
            do {
                actualResults.append(
                    try queueWaiter.waitForJobToFinish(
                        queueServer: server,
                        automaticTerminationController: terminationController,
                        jobId: self.jobId
                    )
                )
                expectationForResults.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        let bucketFetcher = BucketFetcherImpl(
            requestSender: RequestSenderImpl(
                logger: .noOp,
                urlSession: URLSession.shared,
                queueServerAddress: queueServerAddress(port: port)
            )
        )
        
        try runSyncronously { [callbackQueue, workerId, payloadSignature] completion in
            bucketFetcher.fetch(
                payloadSignature: payloadSignature,
                workerCapabilities: [],
                workerId: workerId,
                callbackQueue: callbackQueue
            ) { _ in
                completion(Void())
            }
        }
        
        let resultSender = BucketResultSenderImpl(
            requestSender: RequestSenderImpl(
                logger: .noOp,
                urlSession: URLSession.shared,
                queueServerAddress: queueServerAddress(port: port)
            )
        )
        
        let response: Either<BucketId, Error> = try runSyncronously { [callbackQueue, workerId, payloadSignature] completion in
            resultSender.send(
                bucketId: bucket.bucketId,
                testingResult: testingResult,
                workerId: workerId,
                payloadSignature: payloadSignature,
                callbackQueue: callbackQueue,
                completion: completion
            )
        }
        
        XCTAssertEqual(
            try? response.dematerialize(),
            fixedBucketId,
            "Server is expected to return a bucket id of accepted testing result"
        )
        
        wait(for: [expectationForResults], timeout: 10)

        XCTAssertEqual(
            [JobResults(jobId: jobId, testingResults: [testingResult])],
            actualResults
        )
    }
    
    private func queueServerAddress(port: SocketModels.Port) -> SocketAddress {
        return SocketAddress(host: "localhost", port: port)
    }
}
