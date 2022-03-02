import Foundation
import EmceeLogging

public protocol SpecificTestDiscoverer {
    func discoverTestEntries(
        configuration: AppleTestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry]
}
