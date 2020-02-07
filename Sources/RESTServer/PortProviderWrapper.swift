import Foundation

public final class PortProviderWrapper: PortProvider {
    private let provider: () throws -> Int

    public init(provider: @escaping () throws -> Int) {
        self.provider = provider
    }
    
    public func localPort() throws -> Int {
        return try provider()
    }
}
