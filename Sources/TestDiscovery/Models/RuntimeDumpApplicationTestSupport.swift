import BuildArtifacts
import RunnerModels
import SimulatorPoolModels

public struct RuntimeDumpApplicationTestSupport: Hashable {
    public let appBundle: AppBundleLocation
    public let simulatorControlTool: SimulatorControlTool

    public init(
        appBundle: AppBundleLocation,
        simulatorControlTool: SimulatorControlTool
    ) {
        self.appBundle = appBundle
        self.simulatorControlTool = simulatorControlTool
    }
}
