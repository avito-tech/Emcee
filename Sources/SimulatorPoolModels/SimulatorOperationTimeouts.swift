import Foundation

public struct SimulatorOperationTimeouts: Codable, CustomStringConvertible, Hashable {
    public let create: TimeInterval
    public let boot: TimeInterval
    public let delete: TimeInterval
    public let shutdown: TimeInterval
    
    /// When simulator becomes idle (not executing any test), Emcee will automatically shut it down after this period of time.
    /// This is useful for freeing up RAM and reducing swap size.
    public let automaticSimulatorShutdown: TimeInterval
    
    /// When simulator has been shut down and stays idle, Emcee will automatially delete it after this period of time.
    /// This is useful for freeing up disk space.
    public let automaticSimulatorDelete: TimeInterval

    public init(
        create: TimeInterval,
        boot: TimeInterval,
        delete: TimeInterval,
        shutdown: TimeInterval,
        automaticSimulatorShutdown: TimeInterval,
        automaticSimulatorDelete: TimeInterval
    ) {
        self.create = create
        self.boot = boot
        self.delete = delete
        self.shutdown = shutdown
        self.automaticSimulatorShutdown = automaticSimulatorShutdown
        self.automaticSimulatorDelete = automaticSimulatorDelete
    }
    
    public var description: String {
        return "<\(type(of: self)): create: \(create), boot: \(boot), delete: \(delete), shutdown: \(shutdown), automatic shutdown: \(automaticSimulatorShutdown), automatic delete: \(automaticSimulatorDelete)>"
    }
}
