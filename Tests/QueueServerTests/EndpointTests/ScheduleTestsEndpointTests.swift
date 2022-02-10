import CommonTestModels
import CommonTestModelsTestHelpers
import DateProviderTestHelpers
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import ScheduleStrategy
import TestHelpers
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class ScheduleTestsEndpointTests: XCTestCase {
    func test___scheduling_tests() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let endpoint = createEndpoint(timeout: 0)
        
        let response = try endpoint.handle(
            payload: ScheduleTestsPayload(
                prioritizedJob: prioritizedJob,
                scheduleStrategy: individualScheduleStrategy,
                similarlyConfiguredTestEntries: similarlyConfiguredTestEntries
            )
        )
        
        XCTAssertEqual(response, .scheduledTests)
        
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[prioritizedJob],
            [
                BucketFixtures().with(bucketId: fixedBucketId).bucket(),
            ]
        )
    }
    
    func test___scheduling_no_tests() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let endpoint = createEndpoint(timeout: 0)
        
        let response = try endpoint.handle(
            payload: ScheduleTestsPayload(
                prioritizedJob: prioritizedJob,
                scheduleStrategy: individualScheduleStrategy,
                similarlyConfiguredTestEntries: similarlyConfiguredTestEntries
            )
        )
        
        XCTAssertEqual(response, .scheduledTests)
    }
    
    func test___throws_without_worker_registration() {
        let endpoint = createEndpoint(timeout: 0)
        
        assertThrows {
            try endpoint.handle(
                payload: ScheduleTestsPayload(
                    prioritizedJob: prioritizedJob,
                    scheduleStrategy: individualScheduleStrategy,
                    similarlyConfiguredTestEntries: similarlyConfiguredTestEntries
                )
            )
        }
    }
    
    func test___throws_without_capable_workers() {
        let endpoint = createEndpoint(timeout: 0)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        assertThrows {
            try endpoint.handle(
                payload: ScheduleTestsPayload(
                    prioritizedJob: prioritizedJob,
                    scheduleStrategy: individualScheduleStrategy,
                    similarlyConfiguredTestEntries: SimilarlyConfiguredTestEntries(
                        testEntries: [
                            TestEntryFixtures.testEntry(),
                        ],
                        testEntryConfiguration: TestEntryConfigurationFixtures()
                            .with(
                                workerCapabilityRequirements: [
                                    WorkerCapabilityRequirement(capabilityName: "name", constraint: .present),
                                ]
                            )
                            .testEntryConfiguration()
                    )
                )
            )
        }
    }
    
    func test___waits_for_worker_registration() throws {
        let endpoint = createEndpoint(timeout: 10)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            self.workerAlivenessProvider.didRegisterWorker(workerId: self.workerId)
        }
        
        let response = try endpoint.handle(
            payload: ScheduleTestsPayload(
                prioritizedJob: prioritizedJob,
                scheduleStrategy: individualScheduleStrategy,
                similarlyConfiguredTestEntries: similarlyConfiguredTestEntries
            )
        )
        
        XCTAssertEqual(response, .scheduledTests)
    }
    
    func test___waits_for_capable_worker() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        workerCapabilitiesStorage.set(
            workerCapabilities: [
                WorkerCapability(name: "name", value: "value"),
            ],
            forWorkerId: capableWorkerId
        )
        
        let endpoint = createEndpoint(timeout: 10)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            self.workerAlivenessProvider.didRegisterWorker(workerId: self.capableWorkerId)
        }
        
        let response = try endpoint.handle(
            payload: ScheduleTestsPayload(
                prioritizedJob: prioritizedJob,
                scheduleStrategy: individualScheduleStrategy,
                similarlyConfiguredTestEntries: SimilarlyConfiguredTestEntries(
                    testEntries: [
                        TestEntryFixtures.testEntry(),
                    ],
                    testEntryConfiguration: TestEntryConfigurationFixtures()
                        .with(
                            workerCapabilityRequirements: [
                                WorkerCapabilityRequirement(capabilityName: "name", constraint: .equal("value")),
                            ]
                        )
                        .testEntryConfiguration()
                )
            )
        )
        
        XCTAssertEqual(response, .scheduledTests)
    }
    
    func test___indicates_activity() {
        let endpoint = createEndpoint(timeout: 0)
        XCTAssertTrue(
            endpoint.requestIndicatesActivity,
            "This endpoint should indicate activity because it means queue is being used by the user to add tests for execution"
        )
    }
    
    private func createEndpoint(timeout: TimeInterval) -> ScheduleTestsEndpoint {
        ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            waitForCapableWorkerTimeout: timeout,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
    }

    private lazy var fixedBucketId: BucketId = "fixedBucketId"
    private lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
        value: fixedBucketId.value
    )
    private lazy var bucketSplitInfo = BucketSplitInfo(
        numberOfWorkers: 0,
        numberOfParallelBuckets: 0
    )
    private lazy var jobId = JobId(value: "jobId")
    private lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: jobId,
        jobPriority: .medium
    )
    
    private lazy var similarlyConfiguredTestEntries = SimilarlyConfiguredTestEntries(
        testEntries: [
            TestEntryFixtures.testEntry(),
        ],
        testEntryConfiguration: TestEntryConfigurationFixtures().testEntryConfiguration()
    )
    
    private lazy var enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    private lazy var testsEnqueuer = TestsEnqueuer(
        bucketGenerator: BucketGeneratorImpl(
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        ),
        bucketSplitInfo: bucketSplitInfo,
        dateProvider: DateProviderFixture(),
        enqueueableBucketReceptor: enqueueableBucketReceptor,
        logger: .noOp,
        version: Version(value: "version"),
        specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider()
    )
    private lazy var workerId: WorkerId = "worker"
    private lazy var capableWorkerId: WorkerId = "capableWorkerId"
    private lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    private lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    private lazy var individualScheduleStrategy = ScheduleStrategy(
        testSplitterType: .individual
    )
}
