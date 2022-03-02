public protocol TestDiscoverer {
    associatedtype C: TestDiscoveryConfiguration
    
    func query(configuration: C) throws -> TestDiscoveryResult
}

public protocol AppleTestDiscoverer {
    func query(configuration: AppleTestDiscoveryConfiguration) throws -> TestDiscoveryResult
}
