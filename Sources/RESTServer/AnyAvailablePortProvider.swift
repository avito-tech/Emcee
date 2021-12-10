import Foundation
import SocketModels

public final class AnyAvailablePortProvider: PortProvider {
    public init() {}
    
    public func localPort() throws -> SocketModels.Port {
        0
    }
}
