import DeveloperDirLocator
import Dispatch
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolModels

public final class SimctlBasedSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor, CustomStringConvertible {
    
    public enum SimctlUdidParseError: Error, CustomStringConvertible {
        case emptyUdid
        
        public var description: String {
            switch self {
            case .emptyUdid:
                return "Simctl returned an empty udid value, ot the value was not found"
            }
        }
    }

    private let processControllerProvider: ProcessControllerProvider
    private let simulatorSetPath: AbsolutePath

    public init(processControllerProvider: ProcessControllerProvider, simulatorSetPath: AbsolutePath) {
        self.processControllerProvider = processControllerProvider
        self.simulatorSetPath = simulatorSetPath
    }
    
    public var description: String {
        return "simctl with set path \(simulatorSetPath)"
    }
    
    public func performCreateSimulatorAction(
        environment: [String: String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws -> Simulator {
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
                    "create",
                    "Emcee Sim \(testDestination.deviceType) \(testDestination.runtime)",
                    "com.apple.CoreSimulator.SimDeviceType." + testDestination.deviceType.replacingOccurrences(of: " ", with: "-"),
                    "com.apple.CoreSimulator.SimRuntime.iOS-" + testDestination.runtime.replacingOccurrences(of: ".", with: "-")
                ],
                environment: environment,
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try controller.startAndWaitForSuccessfulTermination()
        
        let createdUdid = try String(contentsOf: controller.subprocess.standardStreamsCaptureConfig.stdoutContentsFile.fileUrl, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !createdUdid.isEmpty else { throw SimctlUdidParseError.emptyUdid }
        
        let udid = UDID(value: createdUdid)
        
        return Simulator(
            testDestination: testDestination,
            udid: udid,
            path: simulatorSetPath.appending(component: udid.value)
        )
    }
    
    public func performBootSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulator.simulatorSetPath,
                    "bootstatus", simulator.udid.value,
                    "-bd"
                ],
                environment: environment,
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try processController.startAndWaitForSuccessfulTermination()
    }
    
    public func performShutdownSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        let shutdownController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulator.simulatorSetPath,
                    "shutdown", simulator.udid.value
                ],
                environment: environment,
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try shutdownController.startAndWaitForSuccessfulTermination()
    }
    
    public func performDeleteSimulatorAction(
        environment: [String: String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        let deleteController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulator.simulatorSetPath,
                    "delete", simulator.udid.value
                ],
                environment: environment,
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try deleteController.startAndWaitForSuccessfulTermination()
    }
}
