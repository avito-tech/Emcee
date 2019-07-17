public final class RuntimeDumpApplicationTestSupport: Equatable {
    enum Error: Swift.Error, CustomStringConvertible {
        case badArguments

        public var description: String {
            switch self {
            case .badArguments:
                return "RuntimeDumpApplicationTestSupport constructor requires either both arguments provided or both omitted"
            }
        }
    }

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

    public convenience init?(
        appBundle: AppBundleLocation?,
        simulatorControlTool: SimulatorControlTool?
    ) throws {
        guard (appBundle == nil && simulatorControlTool == nil) || (appBundle != nil && simulatorControlTool != nil) else {
            throw Error.badArguments
        }

        guard let appBundle = appBundle, let simulatorControlTool = simulatorControlTool else {
            return nil
        }

        self.init(appBundle: appBundle, simulatorControlTool: simulatorControlTool)
    }

    public static func == (left: RuntimeDumpApplicationTestSupport, right: RuntimeDumpApplicationTestSupport) -> Bool {
        return left.appBundle == right.appBundle
            && left.simulatorControlTool == right.simulatorControlTool
    }
}
