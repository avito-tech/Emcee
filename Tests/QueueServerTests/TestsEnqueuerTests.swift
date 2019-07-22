import BucketQueueTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import ScheduleStrategy
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class TestsEnqueuerTests: XCTestCase {
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    let prioritizedJob = PrioritizedJob(jobId: "jobId", priority: .medium)
    
    func test() {
        let bucketId = BucketId(value: UUID().uuidString)
        let testsEnqueuer = TestsEnqueuer(
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(),
            enqueueableBucketReceptor: enqueueableBucketReceptor
        )
        
        testsEnqueuer.enqueue(
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

