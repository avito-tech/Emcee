import Foundation
import EmceeLogging
import QueueModels
import UniqueIdentifierGenerator

public struct BucketSplitInfo {
    public let numberOfWorkers: UInt
    
    public init(
        numberOfWorkers: UInt
    ) {
        self.numberOfWorkers = numberOfWorkers
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
        fatalError("BucketSplitter cannot be used directly, you must use subclass")
    }
    
    open func map(chunk: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [Bucket] {
        let groups = GroupedTestEntryConfigurations(testEntryConfigurations: chunk).grouped()
        
        return groups.compactMap { (group: [TestEntryConfiguration]) -> Bucket? in
            guard let entry = group.first else { return nil }
            return Bucket(
                analyticsConfiguration: entry.analyticsConfiguration,
                bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                buildArtifacts: entry.buildArtifacts,
                developerDir: entry.developerDir,
                pluginLocations: entry.pluginLocations,
                simulatorControlTool: entry.simulatorControlTool,
                simulatorOperationTimeouts: entry.simulatorOperationTimeouts,
                simulatorSettings: entry.simulatorSettings,
                testDestination: entry.testDestination,
                testEntries: group.map { $0.testEntry },
                testExecutionBehavior: entry.testExecutionBehavior,
                testRunnerTool: entry.testRunnerTool,
                testTimeoutConfiguration: entry.testTimeoutConfiguration,
                testType: entry.testType,
                workerCapabilityRequirements: entry.workerCapabilityRequirements
            )
        }
    }
}
