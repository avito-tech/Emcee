import Foundation
import Models

public final class BucketFixtures {
    public static func createBucket(testEntries: [TestEntry]) -> Bucket {
        return Bucket(
            testEntries: testEntries,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            environment: [:],
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            toolResources: ToolResourcesFixtures.fakeToolResources()
        )
    }
}
