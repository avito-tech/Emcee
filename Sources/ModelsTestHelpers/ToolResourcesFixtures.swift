import Foundation
import Models

public final class ToolResourcesFixtures {
    public static func fakeToolResources() -> ToolResources {
        return ToolResources(
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            fbxctest: FbxctestLocation(.remoteUrl(URL(string: "http://example.com")!))
        )
    }
}
