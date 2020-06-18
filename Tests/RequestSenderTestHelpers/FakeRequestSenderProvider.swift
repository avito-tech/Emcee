import Foundation
import Models
import RequestSender

public final class FakeRequestSenderProvider: RequestSenderProvider {
    public var generator: (SocketAddress) -> RequestSender
    
    public convenience init(requestSender: RequestSender) {
        self.init { _ in requestSender }
    }

    public init(generator: @escaping (SocketAddress) -> RequestSender) {
        self.generator = generator
    }
    
    public var receivedSocketAddress: SocketAddress?
    public func requestSender(socketAddress: SocketAddress) -> RequestSender {
        receivedSocketAddress = socketAddress
        return generator(socketAddress)
    }
}
