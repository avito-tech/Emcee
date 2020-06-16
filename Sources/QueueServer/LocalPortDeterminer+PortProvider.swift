import Models
import PortDeterminer
import RESTServer

extension LocalPortDeterminer: PortProvider {
    public func localPort() throws -> Port {
        return try availableLocalPort()
    }
}
