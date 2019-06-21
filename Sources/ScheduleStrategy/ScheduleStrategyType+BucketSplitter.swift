import Foundation
import Models
import UniqueIdentifierGenerator

public extension ScheduleStrategyType {
    func bucketSplitter(uniqueIdentifierGenerator: UniqueIdentifierGenerator) -> BucketSplitter {
        switch self {
        case .individual:
            return IndividualBucketSplitter(uniqueIdentifierGenerator: uniqueIdentifierGenerator)
        case .equallyDivided:
            return EquallyDividedBucketSplitter(uniqueIdentifierGenerator: uniqueIdentifierGenerator)
        case .continuous:
            return ContinuousBucketSplitter(uniqueIdentifierGenerator: uniqueIdentifierGenerator)
        case .progressive:
            return ProgressiveBucketSplitter(uniqueIdentifierGenerator: uniqueIdentifierGenerator)
        }
    }
}
