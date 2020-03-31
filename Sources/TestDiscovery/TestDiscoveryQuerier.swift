import Models

public protocol TestDiscoveryQuerier {
    func query(configuration: TestDiscoveryConfiguration) throws -> TestDiscoveryResult
}
