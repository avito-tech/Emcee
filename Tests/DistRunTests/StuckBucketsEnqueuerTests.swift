@testable import DistRun
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class StuckBucketsEnqueuerTests: XCTestCase {
    func test__stuck_buckets_are_crushed_into_chunks_with_single_bucket_in_each() {
        let testEntries = [
            TestEntry(className: "class1", methodName: "method", caseId: nil),
            TestEntry(className: "class2", methodName: "method", caseId: nil),
            TestEntry(className: "class3", methodName: "method", caseId: nil)]
        let bucket = BucketFixtures.createBucket(testEntries: testEntries)
        let stuckBucket = StuckBucket(reason: .workerIsBlocked, bucket: bucket, workerId: "worker")
        let bucketQueue = FakeBucketQueue(fixedStuckBuckets: [stuckBucket])
        
        let enqueuer = StuckBucketsEnqueuer(bucketQueue: bucketQueue)
        enqueuer.processStuckBuckets()
        
        XCTAssertEqual(bucketQueue.enqueuedBuckets, testEntries.map { BucketFixtures.createBucket(testEntries: [$0]) })
    }
}
