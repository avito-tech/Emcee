import Foundation
import EmceeLogging
import QueueModels
import UniqueIdentifierGenerator

public final class ProgressiveBucketSplitter: BucketSplitter {
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        equallyDividedSplitter = EquallyDividedBucketSplitter(
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )

        super.init(
            description: "Progressive schedule strategy",
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    private let equallyDividedSplitter: EquallyDividedBucketSplitter
    
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        /*
         Here we split all tests to achieve a better loading of the remote machines:
         
         [-----------Group A-----------][------Group B-----][-Group C-][-D-][...]
         
         Group A - 40% of testEntries will be split to the buckets with equal size so each worker will get one big bucket
         Group B - another smaller %% of testEntries will be split to the buckets with equal size, but the size will be smaller
         Group C, Group D, ... - each group will have even a smaller number of tests
         */
        
        let groupedEntriesToRunEqually = inputs.splitToVariableChunks(
            withStartingRelativeSize: 0.4,
            changingRelativeSizeBy: 0.6)
        return groupedEntriesToRunEqually
    }
    
    public override func map(chunk: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [Bucket] {
        return equallyDividedSplitter.generate(inputs: chunk, splitInfo: bucketSplitInfo)
    }
}
