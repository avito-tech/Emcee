import BuildArtifacts
import Models

public struct RuntimeDumpApplicationTestSupport: Hashable {

    /** Path to hosting application*/
    public let appBundle: AppBundleLocation

    /** Path to Fbsimctl to run simulator*/
    public let simulatorControlTool: SimulatorControlTool

    public init(
        appBundle: AppBundleLocation,
        simulatorControlTool: SimulatorControlTool
    ) {
        self.appBundle = appBundle
        self.simulatorControlTool = simulatorControlTool
    }
}
