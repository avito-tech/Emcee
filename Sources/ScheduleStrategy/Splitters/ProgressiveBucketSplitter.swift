import Foundation
import EmceeLogging
import QueueModels
import UniqueIdentifierGenerator

public struct ProgressiveBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        configuredTestEntries: [ConfiguredTestEntry],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[ConfiguredTestEntry]] {
        /*
         Here we split all tests to achieve a better loading of the remote machines:
         
         [-----------Group A-----------][------Group B-----][-Group C-][-D-][...]
         
         Group A - 50% of testEntries will be split to the buckets with equal size so each worker will get one big bucket
         Group B - another smaller %% of testEntries will be split to the buckets with equal size, but the size will be smaller
         Group C, Group D, ... - each group will have even a smaller number of tests
         */
        
        let groupedEntriesToRunEqually = configuredTestEntries.splitToVariableChunks(
            withStartingRelativeSize: 0.7,
            changingRelativeSizeBy: 0.4
        ).flatMap {
            $0.splitToChunks(count: bucketSplitInfo.numberOfParallelBuckets)
        }.sorted { l, r in
            l.count > r.count
        }
        return groupedEntriesToRunEqually
    }
}
