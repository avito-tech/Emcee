import Foundation
import EmceeLogging

protocol SpecificTestDiscoverer {
    func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry]
}
