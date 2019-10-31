import Foundation
import Models
import PathLib
import SimulatorPool

public final class FakeSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor {
    private let create: ([String : String], TestDestination, TimeInterval) throws -> Simulator
    private let boot: ([String : String], AbsolutePath, UDID, TimeInterval) throws -> ()
    private let shutdown: ([String : String], AbsolutePath, UDID, TimeInterval) throws -> ()
    private let delete: ([String : String], AbsolutePath, UDID, TimeInterval) throws -> ()
    
    public init(
        create: @escaping ([String : String], TestDestination, TimeInterval) throws -> Simulator,
        boot: @escaping ([String : String], AbsolutePath, UDID, TimeInterval) throws -> () = { _, _, _, _ in },
        shutdown: @escaping ([String : String], AbsolutePath, UDID, TimeInterval) throws -> () = { _, _, _, _ in },
        delete: @escaping ([String : String], AbsolutePath, UDID, TimeInterval) throws -> () = { _, _, _, _ in }
    ) {
        self.create = create
        self.boot = boot
        self.shutdown = shutdown
        self.delete = delete
    }
    
    public func performCreateSimulatorAction(environment: [String : String], testDestination: TestDestination, timeout: TimeInterval) throws -> Simulator {
        return try create(environment, testDestination, timeout)
    }
    
    public func performBootSimulatorAction(environment: [String : String], path: AbsolutePath, simulatorUuid: UDID, timeout: TimeInterval) throws {
        try boot(environment, path, simulatorUuid, timeout)
    }
    
    public func performShutdownSimulatorAction(environment: [String : String], path: AbsolutePath, simulatorUuid: UDID, timeout: TimeInterval) throws {
        try shutdown(environment, path, simulatorUuid, timeout)
    }
    
    public func performDeleteSimulatorAction(environment: [String : String], path: AbsolutePath, simulatorUuid: UDID, timeout: TimeInterval) throws {
        try delete(environment, path, simulatorUuid, timeout)
    }
}
