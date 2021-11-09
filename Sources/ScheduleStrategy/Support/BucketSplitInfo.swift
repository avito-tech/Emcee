import Foundation

public struct BucketSplitInfo {
    public let numberOfWorkers: UInt
    public let numberOfParallelBuckets: UInt
    
    public init(
        numberOfWorkers: UInt,
        numberOfParallelBuckets: UInt
    ) {
        self.numberOfWorkers = numberOfWorkers
        self.numberOfParallelBuckets = numberOfParallelBuckets
    }
}
