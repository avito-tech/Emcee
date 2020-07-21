import Foundation
import SocketModels

public protocol RequestSenderProvider {
    func requestSender(socketAddress: SocketAddress) -> RequestSender
}
