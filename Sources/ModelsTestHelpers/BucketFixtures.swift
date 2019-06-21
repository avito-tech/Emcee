import Foundation
import Models

public final class BucketFixtures {
    public static func createBucket(
        bucketId: String = "BucketFixturesFixedBucketId",
        testEntries: [TestEntry] = [TestEntryFixtures.testEntry()],
        numberOfRetries: UInt = 0)
        -> Bucket
    {
        return Bucket(
            bucketId: bucketId,
            testEntries: testEntries,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: numberOfRetries),
            toolResources: ToolResourcesFixtures.fakeToolResources(),
            testType: TestType.uiTest
        )
    }
}
