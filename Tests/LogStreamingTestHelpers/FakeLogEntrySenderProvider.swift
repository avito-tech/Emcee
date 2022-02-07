import Foundation
import LogStreaming
import SocketModels

open class FakeLogEntrySenderProvider: LogEntrySenderProvider {
    public var provider: (SocketAddress) -> LogEntrySender
    
    public var providedFakeLogEntrySenders: [FakeLogEntrySender] {
        providedLogEntrySenders.compactMap { $0 as? FakeLogEntrySender }
    }
    
    public init(
        provider: @escaping (SocketAddress) -> LogEntrySender = { socketAddress in
            FakeLogEntrySender(socketAddress: socketAddress)
        }
    ) {
        self.provider = provider
    }
    
    public var providedLogEntrySenders = [LogEntrySender]()
    
    public func create(socketAddress: SocketAddress) -> LogEntrySender {
        let logEntrySender = provider(socketAddress)
        providedLogEntrySenders.append(logEntrySender)
        return logEntrySender
    }
}
