import SocketModels

public protocol PortProvider {
    func localPort() throws -> SocketModels.Port
}

