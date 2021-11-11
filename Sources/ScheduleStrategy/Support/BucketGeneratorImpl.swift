import Foundation
import QueueModels
import UniqueIdentifierGenerator

public class BucketGeneratorImpl: BucketGenerator {
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func generateBuckets(
        testEntryConfigurations: [TestEntryConfiguration],
        splitInfo: BucketSplitInfo,
        testSplitter: TestSplitter
    ) -> [Bucket] {
        let groups = GroupedTestEntryConfigurations(testEntryConfigurations: testEntryConfigurations).grouped()
        
        return groups.flatMap { (groupOfTestEntryConfigurations: [TestEntryConfiguration]) -> [Bucket] in
            let chunks = testSplitter.split(
                testEntryConfigurations: groupOfTestEntryConfigurations,
                bucketSplitInfo: splitInfo
            )
            return chunks.flatMap {
                map(chunk: $0, bucketSplitInfo: splitInfo)
            }
        }
    }
    
    private func map(chunk: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [Bucket] {
        let groups = GroupedTestEntryConfigurations(testEntryConfigurations: chunk).grouped()
        
        return groups.compactMap { (group: [TestEntryConfiguration]) -> Bucket? in
            guard let entry = group.first else { return nil }
            return Bucket.newBucket(
                bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                analyticsConfiguration: entry.analyticsConfiguration,
                pluginLocations: entry.pluginLocations,
                workerCapabilityRequirements: entry.workerCapabilityRequirements,
                runTestsBucketPayload: RunTestsBucketPayload(
                    buildArtifacts: entry.buildArtifacts,
                    developerDir: entry.developerDir,
                    simulatorControlTool: entry.simulatorControlTool,
                    simulatorOperationTimeouts: entry.simulatorOperationTimeouts,
                    simulatorSettings: entry.simulatorSettings,
                    testDestination: entry.testDestination,
                    testEntries: group.map { $0.testEntry },
                    testExecutionBehavior: entry.testExecutionBehavior,
                    testRunnerTool: entry.testRunnerTool,
                    testTimeoutConfiguration: entry.testTimeoutConfiguration,
                    testType: entry.testType
                )
            )
        }
    }
}
