import Foundation
import Models

public extension ScheduleStrategyType {
    func bucketSplitter() -> BucketSplitter {
        switch self {
        case .individual:
            return IndividualBucketSplitter()
        case .equallyDivided:
            return EquallyDividedBucketSplitter()
        case .continuous:
            return ContinuousBucketSplitter()
        case .progressive:
            return ProgressiveBucketSplitter()
        }
    }
}
