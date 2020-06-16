import Models

public final class PortProviderWrapper: PortProvider {
    private let provider: () throws -> Port

    public init(provider: @escaping () throws -> Port) {
        self.provider = provider
    }
    
    public func localPort() throws -> Port {
        return try provider()
    }
}
