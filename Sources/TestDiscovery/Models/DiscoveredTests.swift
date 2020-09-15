public struct DiscoveredTests: Codable, Equatable {
    public let tests: [DiscoveredTestEntry]
    
    public init(tests: [DiscoveredTestEntry]) {
        self.tests = tests
    }
}
