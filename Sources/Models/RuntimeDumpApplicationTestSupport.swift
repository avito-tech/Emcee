public final class RuntimeDumpApplicationTestSupport {
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
}
