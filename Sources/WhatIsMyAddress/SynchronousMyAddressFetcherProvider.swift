import Foundation
import SocketModels

public protocol SynchronousMyAddressFetcherProvider {
    func create(queueAddress: SocketAddress) -> SynchronousMyAddressFetcher
}

