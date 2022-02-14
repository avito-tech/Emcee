@testable import TestDiscovery
import AtomicModels

final class TestDiscoveryQuerierMock: TestDiscoveryQuerier {
    var numberOfCalls = AtomicValue(0)
    var configuration = AtomicValue<TestDiscoveryConfiguration?>(nil)
    
    var resultProvider: (TestDiscoveryConfiguration) -> TestDiscoveryResult = { _ in
        TestDiscoveryResult(discoveredTests: DiscoveredTests(tests: []), unavailableTestsToRun: [])
    }
     
    func query(configuration: TestDiscoveryConfiguration) throws -> TestDiscoveryResult {
        numberOfCalls.withExclusiveAccess { $0 = $0 + 1 }
        self.configuration.set(configuration)
        
        return resultProvider(configuration)
    }
}
