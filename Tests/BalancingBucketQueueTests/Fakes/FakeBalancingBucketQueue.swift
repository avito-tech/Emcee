import BalancingBucketQueue
import BucketQueue
import DateProviderTestHelpers
import Models
import ModelsTestHelpers
import QueueModels
import QueueModelsTestHelpers
import UniqueIdentifierGeneratorTestHelpers

class FakeBalancingBucketQueue: BalancingBucketQueue {
    
    var dequeueBucketRequestId: RequestId?
    var dequeuBucketWorkerId: WorkerId?
    var dequeueBucketDequeueResult: DequeueResult = .queueIsEmpty
    
    func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        dequeueBucketRequestId = requestId
        dequeuBucketWorkerId = workerId
        return dequeueBucketDequeueResult
    }

    func accept(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        let testEntries = testingResult.unfilteredResults.map{ $0.testEntry }
        let dateProvider = DateProviderFixture()
        let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
        let bucket = BucketFixtures.createBucket(testEntries: testEntries)

        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: bucket,
                enqueueTimestamp: dateProvider.currentDate(),
                uniqueIdentifier: uniqueIdentifierGenerator.generate()
            ),
            workerId: workerId,
            requestId: requestId
        )

        return BucketQueueAcceptResult(
            dequeuedBucket: dequeuedBucket,
            testingResultToCollect: testingResult
        )
    }

    func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        nil
    }

    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {

    }

    func delete(jobId: JobId) throws {

    }

    func results(jobId: JobId) throws -> JobResults {
        JobResults(jobId: jobId, testingResults: [])
    }

    func state(jobId: JobId) throws -> JobState {
        JobState(jobId: jobId, queueState: .deleted)
    }

    var ongoingJobIds: Set<JobId> {
        return Set()
    }

    var runningQueueState: RunningQueueState {
        RunningQueueState(enqueuedBucketCount: 0, dequeuedBucketCount: 0)
    }

    func reenqueueStuckBuckets() -> [StuckBucket] {
        return []
    }


}
