import Foundation

public protocol PortProvider {
    func localPort() throws -> Int
}

