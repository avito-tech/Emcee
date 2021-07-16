import Foundation
import SocketModels

public protocol QueueServerPortProvider: AnyObject {
    func port() throws -> SocketModels.Port
}
