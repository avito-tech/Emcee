import Models

public protocol PortProvider {
    func localPort() throws -> Port
}

