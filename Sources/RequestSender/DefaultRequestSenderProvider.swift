import Foundation
import Models

public final class DefaultRequestSenderProvider: RequestSenderProvider {
    public init() {
        
    }
    
    public func requestSender(socketAddress: SocketAddress) -> RequestSender {
        return RequestSenderImpl(
            urlSession: URLSession(configuration: .default),
            queueServerAddress: socketAddress
        )
    }
}
