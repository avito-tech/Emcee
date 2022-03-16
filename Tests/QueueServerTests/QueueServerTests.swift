import AutomaticTermination
import CommonTestModelsTestHelpers
import DateProviderTestHelpers
import DistWorkerModels
import DistWorkerModelsTestHelpers
import MetricsExtensions
import PortDeterminer
import QueueClient
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RequestSender
import RequestSenderTestHelpers
import ScheduleStrategy
import SocketModels
import Types
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import XCTest

final class QueueServerTests: XCTestCase {
    private let workerConfigurations = FixedWorkerConfigurations()
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
    private lazy var bucketGenerator = BucketGeneratorImpl(
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    private let bucketSplitInfo = BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1)
    private let payloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    private lazy var workerAlivenessProvider: WorkerAlivenessProvider = WorkerAlivenessProviderImpl(
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
            autoupdatingWorkerPermissionProvider: FakeAutoupdatingWorkerPermissionProvider(),
            bucketGenerator: bucketGenerator,
            bucketSplitInfo: bucketSplitInfo,
            checkAgainTimeInterval: .infinity,
            dateProvider: DateProviderFixture(),
            emceeVersion: "emceeVersion",
            hostname: "hostname",
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
            workerIds: [],
            workersToUtilizeService: FakeWorkersToUtilizeService(),
            useOnlyIPv4: false
        )
        XCTAssertThrowsError(try server.queueResults(jobId: jobId))
    }
    
    func test__queue_returns_results_after_depletion() throws {
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let runAppleTestsPayload = RunAppleTestsPayloadFixture()
            .with(testEntries: [testEntry])
            .runAppleTestsPayload()
        let bucket = BucketFixtures()
            .with(bucketId: fixedBucketId)
            .with(runAppleTestsPayload: runAppleTestsPayload)
            .bucket()
        
        let configuredTestEntry = ConfiguredTestEntryFixture()
            .with(testEntry: testEntry)
            .build()
        let testingResult = TestingResultFixtures()
            .with(testEntry: testEntry)
            .with(manuallyTestDestination: runAppleTestsPayload.testDestination)
            .testingResult()
        
        let bucketResult = BucketResult.testingResult(testingResult)
        
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerCapabilitiesStorage.set(workerCapabilities: [], forWorkerId: workerId)
        
        let terminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: .afterBeingIdle(period: 0.1)
        ).createAutomaticTerminationController()
        let server = QueueServerImpl(
            automaticTerminationController: terminationController,
            autoupdatingWorkerPermissionProvider: FakeAutoupdatingWorkerPermissionProvider(),
            bucketGenerator: bucketGenerator,
            bucketSplitInfo: bucketSplitInfo,
            checkAgainTimeInterval: .infinity,
            dateProvider: DateProviderFixture(),
            emceeVersion: "emceeVersion",
            hostname: "hostname",
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
            workerIds: [],
            workersToUtilizeService: FakeWorkersToUtilizeService(),
            useOnlyIPv4: false
        )
        try server.schedule(
            configuredTestEntries: [configuredTestEntry],
            testSplitter: IndividualBucketSplitter(),
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
                bucketResult: bucketResult,
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
            [JobResults(jobId: jobId, bucketResults: [bucketResult])],
            actualResults
        )
    }
    
    private func queueServerAddress(port: SocketModels.Port) -> SocketAddress {
        return SocketAddress(host: "localhost", port: port)
    }
}
