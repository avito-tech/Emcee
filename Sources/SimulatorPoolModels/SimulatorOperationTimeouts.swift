import Foundation

public struct SimulatorOperationTimeouts: Codable, CustomStringConvertible, Hashable {
    public let create: TimeInterval
    public let boot: TimeInterval
    public let delete: TimeInterval
    public let shutdown: TimeInterval

    public init(
        create: TimeInterval,
        boot: TimeInterval,
        delete: TimeInterval,
        shutdown: TimeInterval
    ) {
        self.create = create
        self.boot = boot
        self.delete = delete
        self.shutdown = shutdown
    }
    
    public var description: String {
        return "<\(type(of: self)): create: \(create), boot: \(boot), delete: \(delete), shutdown: \(shutdown)>"
    }
}
