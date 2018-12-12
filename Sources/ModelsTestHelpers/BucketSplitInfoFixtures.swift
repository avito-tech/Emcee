import Foundation
import Models
import ScheduleStrategy

public final class BucketSplitInfoFixtures {
    public static func bucketSplitInfoFixture(
        numberOfWorkers: UInt = 1,
        environment: [String: String] = [:],
        toolResources: ToolResources = ToolResourcesFixtures.fakeToolResources(),
        simulatorSettings: SimulatorSettings = SimulatorSettingsFixtures().simulatorSettings()
        )
        -> BucketSplitInfo {
        return BucketSplitInfo(
            numberOfWorkers: numberOfWorkers,
            environment: environment,
            toolResources: toolResources,
            simulatorSettings: simulatorSettings
        )
    }
}
