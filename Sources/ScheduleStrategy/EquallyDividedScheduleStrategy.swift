import Foundation
import Models
import Extensions

/** Splits all tests into `numberOfSimulators` chunks. */
public final class EquallyDividedScheduleStrategy: ScheduleStrategy {
    
    public var description = "Equally divided strategy"
    
    public func generateBuckets(
        numberOfDestinations: UInt,
        testEntries: [TestEntry],
        testDestination: TestDestination)
        -> [Bucket]
    {
        let size = UInt(ceil(Double(testEntries.count) / Double(numberOfDestinations)))
        let chunks = testEntries.splitToChunks(withSize: size)
        return chunks.map { Bucket(testEntries: $0, testDestination: testDestination) }
    }
}
