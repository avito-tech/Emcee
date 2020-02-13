import Foundation
import Models
import ModelsTestHelpers
import QueueModels
import QueueServer
import RESTMethods
import ScheduleStrategy
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class ScheduleTestsEndpointTests: XCTestCase {
    func test___scheduling_tests() throws {
        let endpoint = ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        let response = try endpoint.handle(
            decodedPayload: ScheduleTestsRequest(
                requestId: requestId,
                prioritizedJob: prioritizedJob,
                scheduleStrategy: .individual,
                testEntryConfigurations: testEntryConfigurations
            )
        )
        
        XCTAssertEqual(response, ScheduleTestsResponse.scheduledTests(requestId: requestId))
        
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
    
    func test___scheduling_tests_with_same_request_id___does_not_schedule_multiple_times() throws {
        let endpoint = ScheduleTestsEndpoint(
            testsEnqueuer: testsEnqueuer,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        for _ in 0 ... 10 {
            _ = try endpoint.handle(
                decodedPayload: ScheduleTestsRequest(
                    requestId: requestId,
                    prioritizedJob: prioritizedJob,
                    scheduleStrategy: .individual,
                    testEntryConfigurations: testEntryConfigurations
                )
            )
        }
        
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

    private let fixedBucketId: BucketId = "fixedBucketId"
    private lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
        value: fixedBucketId.value
    )
    let bucketSplitInfo = BucketSplitInfo(
        numberOfWorkers: 0
    )
    let jobId = JobId(value: "jobId")
    lazy var prioritizedJob = PrioritizedJob(jobId: jobId, priority: .medium)
    let requestId: RequestId = "requestId"
    let testEntryConfigurations = TestEntryConfigurationFixtures()
        .add(testEntry: TestEntryFixtures.testEntry())
        .testEntryConfigurations()
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    lazy var testsEnqueuer = TestsEnqueuer(
        bucketSplitInfo: bucketSplitInfo,
        enqueueableBucketReceptor: enqueueableBucketReceptor
    )
    
}
