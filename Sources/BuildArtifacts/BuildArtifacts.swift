import Foundation

public enum BuildArtifacts: Codable, Hashable, CustomStringConvertible {
    case iosLogicTests(
        xcTestBundle: XcTestBundle
    )

    case iosApplicationTests(
        xcTestBundle: XcTestBundle,
        appBundle: AppBundleLocation
    )

    case iosUiTests(
        xcTestBundle: XcTestBundle,
        appBundle: AppBundleLocation,
        runner: RunnerAppLocation,
        additionalApplicationBundles: [AdditionalAppBundleLocation]
    )
    
    public var xcTestBundle: XcTestBundle {
        switch self {
        case .iosLogicTests(let xcTestBundle):
            return xcTestBundle
        case .iosApplicationTests(let xcTestBundle, _):
            return xcTestBundle
        case .iosUiTests(let xcTestBundle, _, _, _):
            return xcTestBundle
        }
    }

    private enum CodingKeys: CodingKey {
        case xcTestBundle
        case appBundle
        case runner
        case additionalApplicationBundles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let xcTestBundle = try container.decode(XcTestBundle.self, forKey: .xcTestBundle)

        if let runner = try container.decodeIfPresent(RunnerAppLocation.self, forKey: .runner) {
            let appBundle = try container.decode(AppBundleLocation.self, forKey: .appBundle)
            self = .iosUiTests(
                xcTestBundle: xcTestBundle,
                appBundle: appBundle,
                runner: runner,
                additionalApplicationBundles: try container.decodeIfPresent(
                    [AdditionalAppBundleLocation].self, forKey: .additionalApplicationBundles
                ) ?? []
            )
        } else if let appBundle = try container.decodeIfPresent(AppBundleLocation.self, forKey: .appBundle) {
            self = .iosApplicationTests(
                xcTestBundle: xcTestBundle,
                appBundle: appBundle
            )
        } else {
            self = .iosLogicTests(xcTestBundle: xcTestBundle)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .iosLogicTests(let xcTestBundle):
            try container.encode(xcTestBundle, forKey: .xcTestBundle)

        case .iosApplicationTests(let xcTestBundle, let appBundle):
            try container.encode(xcTestBundle, forKey: .xcTestBundle)
            try container.encode(appBundle, forKey: .appBundle)

        case .iosUiTests(let xcTestBundle, let appBundle, let runner, let additionalApplicationBundles):
            try container.encode(xcTestBundle, forKey: .xcTestBundle)
            try container.encode(appBundle, forKey: .appBundle)
            try container.encode(runner, forKey: .runner)
            try container.encode(additionalApplicationBundles, forKey: .additionalApplicationBundles)
        }
    }
    
    public var description: String {
        switch self {
        case .iosLogicTests(let xcTestBundle):
            return "iOS logic tests \(xcTestBundle)"
        case .iosApplicationTests(let xcTestBundle, let appBundle):
            return "iOS application tests \(xcTestBundle) \(appBundle)"
        case .iosUiTests(let xcTestBundle, let appBundle, let runner, let additionalApplicationBundles):
            return "iOS UI tests \(xcTestBundle) \(appBundle) \(runner) \(additionalApplicationBundles)"
        }
    }
}
