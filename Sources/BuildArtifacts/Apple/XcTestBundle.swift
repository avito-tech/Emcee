public struct XcTestBundle: Codable, Hashable, CustomStringConvertible {
    public let location: TestBundleLocation
    public let testDiscoveryMode: XcTestBundleTestDiscoveryMode

    public init(
        location: TestBundleLocation,
        testDiscoveryMode: XcTestBundleTestDiscoveryMode
    ) {
        self.location = location
        self.testDiscoveryMode = testDiscoveryMode
    }

    private enum CodingKeys: CodingKey {
        case location
        case testDiscoveryMode
    }

    public init(from decoder: Decoder) throws {
        // Try fallback value first
        if let fallbackLocation = try? decoder.singleValueContainer().decode(TestBundleLocation.self) {
            self.location = fallbackLocation
            self.testDiscoveryMode = .parseFunctionSymbols
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.location = try container.decode(TestBundleLocation.self, forKey: .location)
            self.testDiscoveryMode = try container.decode(XcTestBundleTestDiscoveryMode.self, forKey: .testDiscoveryMode)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(testDiscoveryMode, forKey: .testDiscoveryMode)
    }

    public var description: String {
        return "<\(type(of: self)) location: \(location), testDiscoveryMode: \(testDiscoveryMode)>"
    }
}
