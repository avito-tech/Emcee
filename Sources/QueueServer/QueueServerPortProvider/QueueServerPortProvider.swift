import Foundation
import SocketModels

public protocol QueueServerPortProvider: class {
    func port() throws -> SocketModels.Port
}
