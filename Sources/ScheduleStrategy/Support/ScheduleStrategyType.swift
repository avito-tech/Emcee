import Foundation
import UniqueIdentifierGenerator

public struct ScheduleStrategyType: Codable, Equatable {
    public static func == (lhs: ScheduleStrategyType, rhs: ScheduleStrategyType) -> Bool {
        true
    }
    
    public static var progressive: Self { Self() }
    public static var unsplit: Self { Self() }
    public static var individual: Self { Self() }
    
    public func bucketSplitter(
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) -> BucketSplitter {
        return IndividualBucketSplitter(uniqueIdentifierGenerator: uniqueIdentifierGenerator)
    }
}
