import Foundation
import Models

/**
 This claas generates a set of buckets by taking a number of test destinations.
 It will generate list of buckets for each destination and then merge them into a single list,
 preserving an order of each "sublist" (e.g. all iPhone 7 buckets first, all iPhone SE buckets next).
 This is importaint as it is expensive to switch between different kinds of simulators.
 */
public final class BucketsGenerator {
    private init() {}
    
    public static func generateBuckets(
        strategy: ScheduleStrategy,
        numberOfDestinations: UInt,
        testEntries: [TestEntry],
        testDestinations: [TestDestination],
        toolResources: ToolResources)
        -> [Bucket]
    {
        return testDestinations.flatMap { testDestination in
            strategy.generateBuckets(
                numberOfDestinations: numberOfDestinations,
                testEntries: testEntries,
                testDestination: testDestination,
                toolResources: toolResources)
        }
    }
}
