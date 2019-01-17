import Foundation
import Models

public final class BucketFixtures {
    public static func createBucket(
        testEntries: [TestEntry] = [TestEntryFixtures.testEntry()],
        numberOfRetries: UInt = 0)
        -> Bucket
    {
        return Bucket(
            testEntries: testEntries,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: numberOfRetries),
            toolResources: ToolResourcesFixtures.fakeToolResources()
        )
    }
}
