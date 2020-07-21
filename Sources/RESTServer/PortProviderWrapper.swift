import SocketModels

public final class PortProviderWrapper: PortProvider {
    private let provider: () throws -> SocketModels.Port

    public init(provider: @escaping () throws -> SocketModels.Port) {
        self.provider = provider
    }
    
    public func localPort() throws -> SocketModels.Port {
        return try provider()
    }
}
