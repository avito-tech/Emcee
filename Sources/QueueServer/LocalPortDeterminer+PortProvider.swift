import PortDeterminer
import RESTServer
import SocketModels

extension LocalPortDeterminer: PortProvider {
    public func localPort() throws -> Port {
        return try availableLocalPort()
    }
}
