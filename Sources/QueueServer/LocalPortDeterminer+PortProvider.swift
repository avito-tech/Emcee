import Foundation
import PortDeterminer
import RESTServer

extension LocalPortDeterminer: PortProvider {
    public func localPort() throws -> Int {
        return try availableLocalPort()
    }
}
