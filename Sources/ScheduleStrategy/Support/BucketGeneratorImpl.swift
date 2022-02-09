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
                workerCapabilityRequirements: entry.workerCapabilityRequirements,
                payloadContainer: .runIosTests(
                    RunAppleTestsPayload(
                        buildArtifacts: entry.buildArtifacts,
                        developerDir: entry.developerDir,
                        pluginLocations: entry.pluginLocations,
                        simulatorOperationTimeouts: entry.simulatorOperationTimeouts,
                        simulatorSettings: entry.simulatorSettings,
                        simDeviceType: entry.simDeviceType,
                        simRuntime: entry.simRuntime,
                        testEntries: group.map { $0.testEntry },
                        testExecutionBehavior: entry.testExecutionBehavior,
                        testTimeoutConfiguration: entry.testTimeoutConfiguration,
                        testAttachmentLifetime: entry.testAttachmentLifetime
                    )
                )
            )
        }
    }
}
