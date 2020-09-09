import DateProviderTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import RunnerTestHelpers
import ScheduleStrategy
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class ScheduleTestsEndpointTests: XCTestCase {
    func test___scheduling_tests() throws {
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
    
    func test___indicates_activity() {
        XCTAssertTrue(
            endpoint.requestIndicatesActivity,
            "This endpoint should indicate activity because it means queue is being used by the user to add tests for execution"
        )
    }

    lazy var endpoint = ScheduleTestsEndpoint(
        testsEnqueuer: testsEnqueuer,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    private let fixedBucketId: BucketId = "fixedBucketId"
    private lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
        value: fixedBucketId.value
    )
    let bucketSplitInfo = BucketSplitInfo(
        numberOfWorkers: 0
    )
    let jobId = JobId(value: "jobId")
    lazy var prioritizedJob = PrioritizedJob(jobGroupId: "groupId", jobGroupPriority: .medium, jobId: jobId, jobPriority: .medium)
    let testEntryConfigurations = TestEntryConfigurationFixtures()
        .add(testEntry: TestEntryFixtures.testEntry())
        .testEntryConfigurations()
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    lazy var testsEnqueuer = TestsEnqueuer(
        bucketSplitInfo: bucketSplitInfo,
        dateProvider: DateProviderFixture(),
        enqueueableBucketReceptor: enqueueableBucketReceptor,
        version: Version(value: "version")
    )
    
}
