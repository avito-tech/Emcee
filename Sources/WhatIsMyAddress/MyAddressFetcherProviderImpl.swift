import Foundation
import RequestSender
import SocketModels

public final class MyAddressFetcherProviderImpl: MyAddressFetcherProvider {
    private let requestSenderProvider: RequestSenderProvider
    public init(
        requestSenderProvider: RequestSenderProvider
    ) {
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func create(queueAddress: SocketAddress) -> MyAddressFetcher {
        MyAddressFetcherImpl(
            requestSender: requestSenderProvider.requestSender(
                socketAddress: queueAddress
            )
        )
    }
}
