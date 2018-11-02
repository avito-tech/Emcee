import Extensions
import Foundation
import Logging
import Models

public final class ProgressiveScheduleStrategy: ScheduleStrategy {
    
    public var description = "Progressive schedule strategy"
    
    public func generateBuckets(
        numberOfDestinations: UInt,
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources)
        -> [Bucket]
    {        
        /*
         Here we split all tests to achieve a better loading of the remote machines:
         
         [-----------Group A-----------][------Group B-----][-Group C-][-D-][...]
         
         Group A - 40% of testEntries will be split to the buckets with equal size so each worker will get one big bucket
         Group B - another smaller %% of testEntries will be split to the buckets with equal size, but the size will be smaller
         Group C, Group D, ... - each group will have even a smaller number of tests
         */
        
        let groupedEntriesToRunEqually = testEntries.splitToVariableChunks(
            withStartingRelativeSize: 0.4,
            changingRelativeSizeBy: 0.6)
        
        let equallyDividedStrategy = EquallyDividedScheduleStrategy()
        return groupedEntriesToRunEqually.flatMap {
            equallyDividedStrategy.generateBuckets(
                numberOfDestinations: numberOfDestinations,
                testEntries: $0,
                testDestination: testDestination,
                toolResources: toolResources)
        }
    }
}
