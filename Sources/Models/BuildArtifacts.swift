import Foundation

public struct BuildArtifacts {
    /** Absolute path to app bundle build artifact, e.g. /path/to/Avito.app */
    public let appBundle: String
    
    /** Absolute path to runner app build artifact (XCTRunner.app), e.g. /path/to/Tests-Runner.app */
    public let runner: String
    
    /** Absolute path to xctest bundle with tests to run. Usually it is a part of Runner.app/Plugins, e.g. /path/to/Runner.app/PlugIns/TestBundle.xctest */
    public let xcTestBundle: String
    
    /** Absolute paths to additional apps that can be launched diring tests e.g. /path/to/OtherApp.app */
    public let additionalApplicationBundles: [String]

    public init(appBundle: String, runner: String, xcTestBundle: String, additionalApplicationBundles: [String]) {
        self.appBundle = appBundle
        self.runner = runner
        self.xcTestBundle = xcTestBundle
        self.additionalApplicationBundles = additionalApplicationBundles
    }
    
    public static func onlyWithXctestBundle(xcTestBundle: String) -> BuildArtifacts {
        return BuildArtifacts(appBundle: "", runner: "", xcTestBundle: xcTestBundle, additionalApplicationBundles: [])
    }
}
