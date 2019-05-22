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
    public let fbsimctl: FbsimctlLocation

    public init(
        appBundle: AppBundleLocation,
        fbsimctl: FbsimctlLocation
    ) {
        self.appBundle = appBundle
        self.fbsimctl = fbsimctl
    }

    public convenience init?(
        appBundle: AppBundleLocation?,
        fbsimctl: FbsimctlLocation?
    ) throws {
        guard (appBundle == nil && fbsimctl == nil) || (appBundle != nil && fbsimctl != nil) else {
            throw Error.badArguments
        }

        guard let appBundle = appBundle, let fbsimctl = fbsimctl else {
            return nil
        }

        self.init(appBundle: appBundle, fbsimctl: fbsimctl)
    }

    public static func == (left: RuntimeDumpApplicationTestSupport, right: RuntimeDumpApplicationTestSupport) -> Bool {
        return left.appBundle == right.appBundle && left.fbsimctl == right.fbsimctl
    }
}
