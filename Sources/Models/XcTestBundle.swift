public final class XcTestBundle: Codable, Hashable, CustomStringConvertible {
    public let location: TestBundleLocation
    public let runtimeDumpKind: RuntimeDumpKind

    public init(
        location: TestBundleLocation,
        runtimeDumpKind: RuntimeDumpKind
    ) {
        self.location = location
        self.runtimeDumpKind = runtimeDumpKind
    }

    private enum CodingKeys: CodingKey {
        case location
        case runtimeDumpKind
    }

    public init(from decoder: Decoder) throws {
        // Try fallback value first
        if let fallbackLocation = try? decoder.singleValueContainer().decode(TestBundleLocation.self) {
            self.location = fallbackLocation
            self.runtimeDumpKind = .logicTest
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.location = try container.decode(TestBundleLocation.self, forKey: .location)
            self.runtimeDumpKind = try container.decode(RuntimeDumpKind.self, forKey: .runtimeDumpKind)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(runtimeDumpKind, forKey: .runtimeDumpKind)
    }

    public var description: String {
        return "<\((type(of: self))) location: \(String(describing: location)), runtimeDumpKind: \(String(describing: runtimeDumpKind))>"
    }

    public static func == (lhs: XcTestBundle, rhs: XcTestBundle) -> Bool {
        return lhs.location == rhs.location && lhs.runtimeDumpKind == rhs.runtimeDumpKind
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.location)
        hasher.combine(self.runtimeDumpKind)
    }
}
