import Foundation

public final class BuildArtifacts: Codable, Hashable, CustomStringConvertible {
    /// Location of app bundle
    public let appBundle: AppBundleLocation
    
    /// Location of runner app build artifact (XCTRunner.app)
    public let runner: RunnerAppLocation
    
    /// Location of xctest bundle with tests to run. Usually it is a part of Runner.app/Plugins.
    public let xcTestBundle: TestBundleLocation
    
    /// Location of additional apps that can be launched diring tests.
    public let additionalApplicationBundles: [AdditionalAppBundleLocation]

    public init(
        appBundle: AppBundleLocation,
        runner: RunnerAppLocation,
        xcTestBundle: TestBundleLocation,
        additionalApplicationBundles: [AdditionalAppBundleLocation])
    {
        self.appBundle = appBundle
        self.runner = runner
        self.xcTestBundle = xcTestBundle
        self.additionalApplicationBundles = additionalApplicationBundles
    }
    
    public static func onlyWithXctestBundle(xcTestBundle: TestBundleLocation) -> BuildArtifacts {
        return BuildArtifacts(
            appBundle: AppBundleLocation(.localFilePath("")),
            runner: RunnerAppLocation(.localFilePath("")),
            xcTestBundle: xcTestBundle,
            additionalApplicationBundles: [])
    }
    
    public static func ==(left: BuildArtifacts, right: BuildArtifacts) -> Bool {
        return left.appBundle == right.appBundle
            && left.runner == right.runner
            && left.xcTestBundle == right.xcTestBundle
            && left.additionalApplicationBundles == right.additionalApplicationBundles
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(appBundle)
        hasher.combine(runner)
        hasher.combine(xcTestBundle)
        hasher.combine(additionalApplicationBundles)
    }
    
    public var description: String {
        return "<\((type(of: self))) appBundle: \(appBundle), runner: \(runner), xcTestBundle: \(xcTestBundle), additionalApplicationBundles: \(additionalApplicationBundles)>"
    }
}
