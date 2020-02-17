import Foundation

public struct BuildArtifacts: Codable, Hashable, CustomStringConvertible {
    /// Location of app bundle
    public let appBundle: AppBundleLocation?
    
    /// Location of runner app build artifact (XCTRunner.app)
    public let runner: RunnerAppLocation?
    
    /// Location of xctest bundle with tests to run. Usually it is a part of Runner.app/Plugins.
    public let xcTestBundle: XcTestBundle
    
    /// Location of additional apps that can be launched diring tests.
    public let additionalApplicationBundles: [AdditionalAppBundleLocation]

    public init(
        appBundle: AppBundleLocation?,
        runner: RunnerAppLocation?,
        xcTestBundle: XcTestBundle,
        additionalApplicationBundles: [AdditionalAppBundleLocation])
    {
        self.appBundle = appBundle
        self.runner = runner
        self.xcTestBundle = xcTestBundle
        self.additionalApplicationBundles = additionalApplicationBundles
    }

    private enum CodingKeys: CodingKey {
        case appBundle
        case runner
        case xcTestBundle
        case additionalApplicationBundles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.appBundle = try container.decodeIfPresent(AppBundleLocation.self, forKey: .appBundle)
        self.runner = try container.decodeIfPresent(RunnerAppLocation.self, forKey: .runner)
        self.xcTestBundle = try container.decode(XcTestBundle.self, forKey: .xcTestBundle)

        self.additionalApplicationBundles = try container.decodeIfPresent(
            [AdditionalAppBundleLocation].self, forKey: .additionalApplicationBundles
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(xcTestBundle, forKey: .xcTestBundle)
        try container.encode(additionalApplicationBundles, forKey: .additionalApplicationBundles)

        if let appBundle = appBundle {
            try container.encode(appBundle, forKey: .appBundle)
        }

        if let runner = runner {
            try container.encode(runner, forKey: .runner)
        }
    }
    
    public static func onlyWithXctestBundle(xcTestBundle: XcTestBundle) -> BuildArtifacts {
        return BuildArtifacts(
            appBundle: nil,
            runner: nil,
            xcTestBundle: xcTestBundle,
            additionalApplicationBundles: []
        )
    }
    
    public var description: String {
        var result: [String] = []
        if let appBundle = appBundle {
            result += ["appBundle: \(appBundle)"]
        }
        if let runner = runner {
            result += ["runner: \(runner)"]
        }
        result += ["xcTestBundle: \(xcTestBundle)"]
        if !additionalApplicationBundles.isEmpty {
            result += ["additionalApplicationBundles: \(additionalApplicationBundles)"]
        }
        return "<\(type(of: self)): " + result.joined(separator: " ") + ">"
    }
}
