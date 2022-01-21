import Foundation
import SocketModels

public protocol LogEntrySenderProvider {
    func create(socketAddress: SocketAddress) -> LogEntrySender
}
