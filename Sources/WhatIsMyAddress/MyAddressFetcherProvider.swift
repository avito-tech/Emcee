import Foundation
import SocketModels

public protocol MyAddressFetcherProvider {
    func create(queueAddress: SocketAddress) -> MyAddressFetcher
}
