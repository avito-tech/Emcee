import BucketQueueTestHelpers
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

final class TestsEnqueuerTests: XCTestCase {
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    let prioritizedJob = PrioritizedJob(jobGroupId: "groupId", jobGroupPriority: .medium, jobId: "jobId", jobPriority: .medium, persistentMetricsJobId: "")
    
    func test() throws {
        let bucketId = BucketId(value: UUID().uuidString)
        let testsEnqueuer = TestsEnqueuer(
            bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 1),
            dateProvider: DateProviderFixture(),
            enqueueableBucketReceptor: enqueueableBucketReceptor,
            version: Version(value: "version")
        )
        
        try testsEnqueuer.enqueue(
            bucketSplitter: ScheduleStrategyType.individual.bucketSplitter(
                uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: bucketId.value)
            ),
            testEntryConfigurations: TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry())
                .testEntryConfigurations(),
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

