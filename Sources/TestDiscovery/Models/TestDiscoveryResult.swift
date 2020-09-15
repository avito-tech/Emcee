import Foundation
import TestArgFile

public struct TestDiscoveryResult: Codable, Equatable, CustomStringConvertible {
    public let discoveredTests: DiscoveredTests
    public let unavailableTestsToRun: [TestToRun]
    
    public init(
        discoveredTests: DiscoveredTests,
        unavailableTestsToRun: [TestToRun]
    ) {
        self.discoveredTests = discoveredTests
        self.unavailableTestsToRun = unavailableTestsToRun
    }

    public var description: String {
        return "Test discovery result: \(discoveredTests.tests.count) tests, missing tests: \(unavailableTestsToRun)"
    }
}
