import EmceeLogging
import Foundation
import SocketModels

public final class DefaultRequestSenderProvider: RequestSenderProvider {
    private let logger: ContextualLogger
    
    public init(logger: ContextualLogger) {
        self.logger = logger.forType(Self.self)
    }
    
    public func requestSender(socketAddress: SocketAddress) -> RequestSender {
        return RequestSenderImpl(
            logger: logger.withMetadata(key: "socketAddress", value: socketAddress.asString),
            urlSession: URLSession(configuration: .default),
            queueServerAddress: socketAddress
        )
    }
}
