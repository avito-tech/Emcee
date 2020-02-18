import Foundation
import Models
import RunnerModels
import SimulatorPoolTestHelpers

public final class ToolResourcesFixtures {
    public static func fakeToolResources() -> ToolResources {
        return ToolResources(
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool
        )
    }
}
