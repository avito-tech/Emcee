import Foundation
import EmceeLogging

public protocol SpecificTestDiscoverer {
    func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry]
}
