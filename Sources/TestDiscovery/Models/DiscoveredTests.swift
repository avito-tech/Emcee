public struct DiscoveredTests: Codable, Equatable, CustomStringConvertible {
    public let tests: [DiscoveredTestEntry]
    
    public init(tests: [DiscoveredTestEntry]) {
        self.tests = tests
    }
    
    public var description: String {
        "<Discovered \(tests.count) tests: \(tests)>"
    }
}
