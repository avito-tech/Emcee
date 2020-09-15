@testable import TestDiscovery

final class TestDiscoveryQuerierMock: TestDiscoveryQuerier {
    var numberOfCalls = 0
    var configuration: TestDiscoveryConfiguration?
    
    var resultProvider: (TestDiscoveryConfiguration) -> TestDiscoveryResult = { _ in
        TestDiscoveryResult(discoveredTests: DiscoveredTests(tests: []), unavailableTestsToRun: [])
    }
     
    func query(configuration: TestDiscoveryConfiguration) throws -> TestDiscoveryResult {
        numberOfCalls += 1
        self.configuration = configuration
        
        return resultProvider(configuration)
    }
}
