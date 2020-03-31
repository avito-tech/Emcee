@testable import TestDiscovery
import Models

final class TestDiscoveryQuerierMock: TestDiscoveryQuerier {
    var numberOfCalls = 0
    var configuration: TestDiscoveryConfiguration?
    func query(configuration: TestDiscoveryConfiguration) throws -> TestDiscoveryResult {
        numberOfCalls += 1
        self.configuration = configuration
        
        return TestDiscoveryResult(
            discoveredTests: DiscoveredTests(tests: []),
            unavailableTestsToRun: []
        )
    }
}
