import BucketQueueTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import ScheduleStrategy
import XCTest

final class TestsEnqueuerTests: XCTestCase {
    let enqueueableBucketReceptor = FakeEnqueueableBucketReceptor()
    let jobId: JobId = "job_id"
    
    func test() {
        
        let testsEnqueuer = TestsEnqueuer(
            bucketSplitter: IndividualBucketSplitter(),
            bucketSplitInfo: BucketSplitInfoFixtures.bucketSplitInfoFixture(),
            enqueueableBucketReceptor: enqueueableBucketReceptor
        )
        
        testsEnqueuer.enqueue(
            testEntryConfigurations: TestEntryConfigurationFixtures()
                .add(testEntry: TestEntryFixtures.testEntry())
                .testEntryConfigurations(),
            jobId: jobId
        )
        
        XCTAssertEqual(
            enqueueableBucketReceptor.enqueuedJobs[jobId],
            [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])]
        )
    }
}

