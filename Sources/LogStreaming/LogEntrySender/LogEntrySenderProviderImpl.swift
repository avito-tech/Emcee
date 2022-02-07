import Foundation
import SocketModels
import RequestSender

public final class LogEntrySenderProviderImpl: LogEntrySenderProvider {
    private let requestSenderProvider: RequestSenderProvider
    
    public init(
        requestSenderProvider: RequestSenderProvider
    ) {
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func create(socketAddress: SocketAddress) -> LogEntrySender {
        LogEntrySenderImpl(
            requestSender: requestSenderProvider.requestSender(
                socketAddress: socketAddress
            )
        )
    }
}
