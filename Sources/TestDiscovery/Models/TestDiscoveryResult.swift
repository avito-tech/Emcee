import Foundation
import Models

public struct TestDiscoveryResult: Codable, Equatable, CustomStringConvertible {
    public let discoveredTests: DiscoveredTests
    public let unavailableTestsToRun: [TestToRun]

    public var description: String {
        return "Test discovery result: \(discoveredTests.tests.count) tests, missing tests: \(unavailableTestsToRun)"
    }
}
