import Foundation
import Logging
import Models
import UniqueIdentifierGenerator

public struct BucketSplitInfo {
    public let numberOfWorkers: UInt
    public let toolResources: ToolResources
    public let simulatorSettings: SimulatorSettings
    
    public init(
        numberOfWorkers: UInt,
        toolResources: ToolResources,
        simulatorSettings: SimulatorSettings
        )
    {
        self.numberOfWorkers = numberOfWorkers
        self.toolResources = toolResources
        self.simulatorSettings = simulatorSettings
    }
}

public class BucketSplitter: Splitter, CustomStringConvertible {
    public typealias Input = TestEntryConfiguration
    public typealias SplitInfo = BucketSplitInfo
    public typealias Output = Bucket
    
    public let description: String
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(description: String, uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        self.description = description
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public final func generate(inputs: [TestEntryConfiguration], splitInfo: BucketSplitInfo) -> [Bucket] {
        let groups = GroupedTestEntryConfigurations(testEntryConfigurations: inputs).grouped()
        
        return groups.flatMap { (groupOfTestEntryConfigurations: [TestEntryConfiguration]) -> [Bucket] in
            let chunks = split(inputs: groupOfTestEntryConfigurations, bucketSplitInfo: splitInfo)
            return chunks.flatMap { map(chunk: $0, bucketSplitInfo: splitInfo) }
        }
    }
    
    open func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        Logger.fatal("BucketSplitter cannot be used, you must use subclass")
    }
    
    open func map(chunk: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [Bucket] {
        let groups = GroupedTestEntryConfigurations(testEntryConfigurations: chunk).grouped()
        
        return groups.compactMap { (group: [TestEntryConfiguration]) -> Bucket? in
            guard let entry = group.first else { return nil }
            return Bucket(
                bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                testEntries: group.map { $0.testEntry },
                buildArtifacts: entry.buildArtifacts,
                simulatorSettings: bucketSplitInfo.simulatorSettings,
                testDestination: entry.testDestination,
                testExecutionBehavior: entry.testExecutionBehavior,
                testType: entry.testType,
                toolResources: bucketSplitInfo.toolResources,
                toolchainConfiguration: entry.toolchainConfiguration
            )
        }
    }
}
