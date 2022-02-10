import CommonTestModels
import Foundation
import PathLib
import SimulatorPool
import SimulatorPoolModels

public final class FakeSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor {
    private let create: ([String: String], SimDeviceType, SimRuntime, TimeInterval) throws -> Simulator
    private let boot: ([String: String], AbsolutePath, UDID, TimeInterval) throws -> ()
    private let shutdown: ([String: String], AbsolutePath, UDID, TimeInterval) throws -> ()
    private let delete: ([String: String], AbsolutePath, UDID, TimeInterval) throws -> ()
    
    public init(
        create: @escaping ([String : String], SimDeviceType, SimRuntime, TimeInterval) throws -> Simulator,
        boot: @escaping ([String : String], AbsolutePath, UDID, TimeInterval) throws -> () = { _, _, _, _ in },
        shutdown: @escaping ([String : String], AbsolutePath, UDID, TimeInterval) throws -> () = { _, _, _, _ in },
        delete: @escaping ([String : String], AbsolutePath, UDID, TimeInterval) throws -> () = { _, _, _, _ in }
    ) {
        self.create = create
        self.boot = boot
        self.shutdown = shutdown
        self.delete = delete
    }
    
    public func performCreateSimulatorAction(
        environment: [String: String],
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
        timeout: TimeInterval
    ) throws -> Simulator {
        return try create(environment, simDeviceType, simRuntime, timeout)
    }
    
    public func performBootSimulatorAction(environment: [String : String], simulator: Simulator, timeout: TimeInterval) throws {
        try boot(environment, simulator.path, simulator.udid, timeout)
    }
    
    public func performShutdownSimulatorAction(environment: [String : String], simulator: Simulator, timeout: TimeInterval) throws {
        try shutdown(environment, simulator.path, simulator.udid, timeout)
    }
    
    public func performDeleteSimulatorAction(environment: [String : String], simulator: Simulator, timeout: TimeInterval) throws {
        try delete(environment, simulator.path, simulator.udid, timeout)
    }
}
