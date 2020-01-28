public final class RuntimeDumpApplicationTestSupport: Hashable {

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

    public static func == (left: RuntimeDumpApplicationTestSupport, right: RuntimeDumpApplicationTestSupport) -> Bool {
        return left.appBundle == right.appBundle
            && left.simulatorControlTool == right.simulatorControlTool
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(appBundle)
        hasher.combine(simulatorControlTool)
    }
}
