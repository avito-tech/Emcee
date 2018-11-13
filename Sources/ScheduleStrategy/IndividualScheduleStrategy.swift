import Foundation
import Models

/** Creates a separate simulator for each test. */
public final class IndividualScheduleStrategy: ScheduleStrategy {
    
    public init() {}
    
    public var description = "Individual strategy"
    
    public func generateBuckets(
        numberOfDestinations: UInt,
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts)
        -> [Bucket]
    {
        return generateIndividualBuckets(
            testEntries: testEntries,
            testDestination: testDestination,
            toolResources: toolResources,
            buildArtifacts: buildArtifacts)
    }
    
    public func generateIndividualBuckets(
        testEntries: [TestEntry],
        testDestination: TestDestination,
        toolResources: ToolResources,
        buildArtifacts: BuildArtifacts)
        -> [Bucket]
    {
        return testEntries.map {
            Bucket(
                testEntries: [$0],
                testDestination: testDestination,
                toolResources: toolResources,
                buildArtifacts: buildArtifacts)
        }
    }
}
