import Foundation
import QueueModels
import UniqueIdentifierGenerator

public class BucketGeneratorImpl: BucketGenerator {
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func generateBuckets(
        configuredTestEntries: [ConfiguredTestEntry],
        splitInfo: BucketSplitInfo,
        testSplitter: TestSplitter
    ) -> [Bucket] {
        let groups = GroupedConfiguredTestEntry(configuredTestEntries: configuredTestEntries).grouped()
        
        return groups.flatMap { (groupConfiguredTestEntries: [ConfiguredTestEntry]) -> [Bucket] in
            let chunks = testSplitter.split(
                configuredTestEntries: groupConfiguredTestEntries,
                bucketSplitInfo: splitInfo
            )
            return chunks.flatMap {
                map(chunk: $0, bucketSplitInfo: splitInfo)
            }
        }
    }
    
    private func map(chunk: [ConfiguredTestEntry], bucketSplitInfo: BucketSplitInfo) -> [Bucket] {
        let groups = GroupedConfiguredTestEntry(configuredTestEntries: chunk).grouped()
        
        return groups.compactMap { (group: [ConfiguredTestEntry]) -> Bucket? in
            guard let entry = group.first else { return nil }
            
            let testEntries = group.map { $0.testEntry }
            
            let payloadContainer: BucketPayloadContainer
            switch entry.testEntryConfiguration.testConfigurationContainer {
            case .appleTest(let appleTestConfiguration):
                payloadContainer = .runAppleTests(
                    RunAppleTestsPayload(
                        testEntries: testEntries,
                        testsConfiguration: appleTestConfiguration
                    )
                )
            case .androidTest(let androidTestConfiguration):
                payloadContainer = .runAndroidTests(
                    RunAndroidTestsPayload(
                        testEntries: testEntries,
                        testConfiguration: androidTestConfiguration
                    )
                )
            }
            
            return Bucket.newBucket(
                bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                analyticsConfiguration: entry.testEntryConfiguration.analyticsConfiguration,
                workerCapabilityRequirements: entry.testEntryConfiguration.workerCapabilityRequirements,
                payloadContainer: payloadContainer
            )
        }
    }
}
