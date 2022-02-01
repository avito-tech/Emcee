import Foundation
import SocketModels
import SynchronousWaiter

public final class SynchronousMyAddressFetcherProviderImpl: SynchronousMyAddressFetcherProvider {
    private let myAddressFetcherProvider: MyAddressFetcherProvider
    private let waiter: Waiter
    
    public init(
        myAddressFetcherProvider: MyAddressFetcherProvider,
        waiter: Waiter
    ) {
        self.myAddressFetcherProvider = myAddressFetcherProvider
        self.waiter = waiter
    }
    
    public func create(
        queueAddress: SocketAddress
    ) -> SynchronousMyAddressFetcher {
        CachingSynchronousMyAddressFetcher(
            wrapped: SynchronousMyAddressFetcherImpl(
                myAddressFetcher: myAddressFetcherProvider.create(
                    queueAddress: queueAddress
                ),
                waiter: waiter
            )
        )
    }
}
