import DateProviderTestHelpers
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import RunnerTestHelpers
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
                scheduleStrategy: .individual,
                testEntryConfigurations: testEntryConfigurations
            )
        )
        
        XCTAssertEqual(response, .scheduledTests)
        
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[prioritizedJob],
            [
                BucketFixtures.createBucket(
                    bucketId: fixedBucketId,
                    testEntries: [TestEntryFixtures.testEntry()]
                )
            ]
        )
    }
    
    func test___scheduling_no_tests() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let endpoint = createEndpoint(timeout: 0)
        
        let response = try endpoint.handle(
            payload: ScheduleTestsPayload(
                prioritizedJob: prioritizedJob,
                scheduleStrategy: .individual,
                testEntryConfigurations: []
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
                    scheduleStrategy: .individual,
                    testEntryConfigurations: testEntryConfigurations
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
                    scheduleStrategy: .individual,
                    testEntryConfigurations: TestEntryConfigurationFixtures()
                        .add(testEntry: TestEntryFixtures.testEntry())
                        .with(workerCapabilityRequirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .present)])
                        .testEntryConfigurations()
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
                scheduleStrategy: .individual,
                testEntryConfigurations: testEntryConfigurations
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
                scheduleStrategy: .individual,
                testEntryConfigurations: TestEntryConfigurationFixtures()
                    .add(testEntry: TestEntryFixtures.testEntry())
                    .with(workerCapabilityRequirements: [WorkerCapabilityRequirement(capabilityName: "name", constraint: .equal("value"))])
                    .testEntryConfigurations()
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

    private let fixedBucketId: BucketId = "fixedBucketId"
    private lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
        value: fixedBucketId.value
    )
    let bucketSplitInfo = BucketSplitInfo(
        numberOfWorkers: 0
    )
    let jobId = JobId(value: "jobId")
    lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: jobId,
        jobPriority: .medium
    )
    let testEntryConfigurations = TestEntryConfigurationFixtures()
        .add(testEntry: TestEntryFixtures.testEntry())
        .testEntryConfigurations()
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    lazy var testsEnqueuer = TestsEnqueuer(
        bucketSplitInfo: bucketSplitInfo,
        dateProvider: DateProviderFixture(),
        enqueueableBucketReceptor: enqueueableBucketReceptor,
        logger: .noOp,
        version: Version(value: "version"),
        specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider()
    )
    lazy var workerId: WorkerId = "worker"
    lazy var capableWorkerId: WorkerId = "capableWorkerId"
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId, capableWorkerId],
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
}
