import BucketQueueTestHelpers
import DateProviderTestHelpers
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import RunnerTestHelpers
import ScheduleStrategy
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class TestsEnqueuerTests: XCTestCase {
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    let prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: "jobId",
        jobPriority: .medium
    )
    
    func test() throws {
        let bucketId = BucketId(value: UUID().uuidString)
        let testsEnqueuer = TestsEnqueuer(
            bucketGenerator: BucketGeneratorImpl(
                uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: bucketId.value)
            ),
            bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1),
            dateProvider: DateProviderFixture(),
            enqueueableBucketReceptor: enqueueableBucketReceptor,
            logger: .noOp,
            version: Version(value: "version"),
            specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider()
        )
        
        try testsEnqueuer.enqueue(
            testEntryConfigurations: TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry())
                .testEntryConfigurations(),
            testSplitter: IndividualBucketSplitter(),
            prioritizedJob: prioritizedJob
        )
        
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[prioritizedJob],
            [
                BucketFixtures.createBucket(
                    bucketId: bucketId, testEntries: [TestEntryFixtures.testEntry()]
                )
            ]
        )
    }
}

