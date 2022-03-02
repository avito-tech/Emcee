@testable import TestDiscovery

final class TestDiscoveryQuerierMock: AppleTestDiscoverer {
    var numberOfCalls = 0
    var configuration: AppleTestDiscoveryConfiguration?
    
    var resultProvider: (AppleTestDiscoveryConfiguration) -> TestDiscoveryResult = { _ in
        TestDiscoveryResult(discoveredTests: DiscoveredTests(tests: []), unavailableTestsToRun: [])
    }
     
    func query(configuration: AppleTestDiscoveryConfiguration) throws -> TestDiscoveryResult {
        numberOfCalls += 1
        self.configuration = configuration
        
        return resultProvider(configuration)
    }
}
