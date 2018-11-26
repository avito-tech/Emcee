import Extensions
import Foundation
import Logging
import Models

public final class ProgressiveBucketSplitter: BucketSplitter {
    public init() {
        super.init(description: "Progressive schedule strategy")
    }
    
    private let equallyDividedSplitter = EquallyDividedBucketSplitter()
    
    public override func split(inputs: [TestEntry], bucketSplitInfo: BucketSplitInfo) -> [[TestEntry]] {
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
    
    public override func generate(inputs: [TestEntry], splitInfo: BucketSplitInfo) -> [Bucket] {
        let groupedEntriesToRunEqually = split(inputs: inputs, bucketSplitInfo: splitInfo)
        return groupedEntriesToRunEqually.flatMap {
            equallyDividedSplitter.generate(inputs: $0, splitInfo: splitInfo)
        }
    }
}
