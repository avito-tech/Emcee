import Foundation
import Models

public struct BucketSplitInfo {
    public let numberOfDestinations: UInt
    public let testDestinations: [TestDestination]
    public let toolResources: ToolResources
    public let buildArtifacts: BuildArtifacts
    
    public init(
        numberOfDestinations: UInt,
        testDestinations: [TestDestination],
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts)
    {
        self.numberOfDestinations = numberOfDestinations
        self.testDestinations = testDestinations
        self.toolResources = toolResources
        self.buildArtifacts = buildArtifacts
    }
}

public class BucketSplitter: Splitter, CustomStringConvertible {
    public typealias Input = TestEntry
    public typealias SplitInfo = BucketSplitInfo
    public typealias Output = Bucket
    
    public let description: String
    
    public init(description: String) {
        self.description = description
    }
    
    public func generate(inputs: [TestEntry], splitInfo: BucketSplitInfo) -> [Bucket] {
        let chunks = split(inputs: inputs, bucketSplitInfo: splitInfo)
        return splitInfo.testDestinations.flatMap { testDestination -> [Bucket] in
            chunks.map { testEntries in
                Bucket(
                    testEntries: testEntries,
                    testDestination: testDestination,
                    toolResources: splitInfo.toolResources,
                    buildArtifacts: splitInfo.buildArtifacts)
            }
        }
    }
    
    open func split(inputs: [TestEntry], bucketSplitInfo: BucketSplitInfo) -> [[TestEntry]] {
        fatalError("BucketSplitter cannot be used, you must use subclass")
    }
}
