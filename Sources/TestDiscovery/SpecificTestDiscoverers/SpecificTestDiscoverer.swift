import Foundation

protocol SpecificTestDiscoverer {
    func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry]
}
