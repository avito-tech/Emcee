import Models

enum TestHistoryTrackerError: Error, CustomStringConvertible {
    case mismatchedBuckedIds(testingResultBucketId: BucketId, bucketId: BucketId)

    public var description: String {
        switch self {
        case let .mismatchedBuckedIds(testingResultBucketId, bucketId):
            return "Bucket id of testing result: \(testingResultBucketId) does not math bucket id: \(bucketId)"
        }
    }
}
