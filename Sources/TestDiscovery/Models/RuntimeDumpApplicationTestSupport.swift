import BuildArtifacts
import SimulatorPoolModels

public struct RuntimeDumpApplicationTestSupport: Hashable {
    public let appBundle: AppBundleLocation

    public init(
        appBundle: AppBundleLocation
    ) {
        self.appBundle = appBundle
    }
}
