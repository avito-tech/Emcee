import Foundation

public enum AndroidBuildArtifacts: Codable, Hashable, CustomStringConvertible {
    case applicationTests(
        appApk: ApkLocation,
        testApk: ApkLocation
    )

    public var testApk: ApkLocation {
        switch self {
        case .applicationTests(_, let testApk):
            return testApk
        }
    }

    private enum CodingKeys: CodingKey {
        case appApk
        case testApk
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self = .applicationTests(
            appApk: try container.decode(ApkLocation.self, forKey: .appApk),
            testApk: try container.decode(ApkLocation.self, forKey: .testApk)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .applicationTests(let appApk, let testApk):
            try container.encode(appApk, forKey: .appApk)
            try container.encode(testApk, forKey: .testApk)
        }
    }
    
    public var description: String {
        switch self {
        case .applicationTests(let appApk, let testApk):
            return "Application tests \(appApk) \(testApk)"
        }
    }
}
