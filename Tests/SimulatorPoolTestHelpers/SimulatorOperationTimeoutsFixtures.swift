import Foundation
import SimulatorPoolModels

public final class SimulatorOperationTimeoutsFixture {
    public var create: TimeInterval
    public var boot: TimeInterval
    public var delete: TimeInterval
    public var shutdown: TimeInterval

    public init(
        create: TimeInterval = 42,
        boot: TimeInterval = 43,
        delete: TimeInterval = 44,
        shutdown: TimeInterval = 45
    ) {
        self.create = create
        self.boot = boot
        self.delete = delete
        self.shutdown = shutdown
    }
    
    public func simulatorOperationTimeouts() -> SimulatorOperationTimeouts {
        return SimulatorOperationTimeouts(
            create: create,
            boot: boot,
            delete: delete,
            shutdown: shutdown
        )
    }
}
