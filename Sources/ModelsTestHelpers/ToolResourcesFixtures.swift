import Foundation
import Models

public final class ToolResourcesFixtures {
    public static func fakeToolResources() -> ToolResources {
        return ToolResources(
            fbsimctl: FbsimctlLocation(.remoteUrl(URL(string: "http://example.com")!)),
            fbxctest: FbxctestLocation(.remoteUrl(URL(string: "http://example.com")!)))
    }
}
