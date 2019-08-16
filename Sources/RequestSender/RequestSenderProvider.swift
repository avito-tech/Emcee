import Foundation
import Models

public protocol RequestSenderProvider {
    func requestSender(socketAddress: SocketAddress) -> RequestSender
}
