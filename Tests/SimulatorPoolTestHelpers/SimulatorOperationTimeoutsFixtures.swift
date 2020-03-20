import Foundation
import SimulatorPoolModels

public final class SimulatorOperationTimeoutsFixture {
    public var create: TimeInterval
    public var boot: TimeInterval
    public var delete: TimeInterval
    public var shutdown: TimeInterval
    public var automaticSimulatorShutdown: TimeInterval
    public var automaticSimulatorDelete: TimeInterval

    public init(
        create: TimeInterval = 42,
        boot: TimeInterval = 43,
        delete: TimeInterval = 44,
        shutdown: TimeInterval = 45,
        automaticSimulatorShutdown: TimeInterval = 46,
        automaticSimulatorDelete: TimeInterval = 47
    ) {
        self.create = create
        self.boot = boot
        self.delete = delete
        self.shutdown = shutdown
        self.automaticSimulatorShutdown = automaticSimulatorShutdown
        self.automaticSimulatorDelete = automaticSimulatorDelete
    }
    
    public func simulatorOperationTimeouts() -> SimulatorOperationTimeouts {
        return SimulatorOperationTimeouts(
            create: create,
            boot: boot,
            delete: delete,
            shutdown: shutdown,
            automaticSimulatorShutdown: automaticSimulatorShutdown,
            automaticSimulatorDelete: automaticSimulatorDelete
        )
    }
}
