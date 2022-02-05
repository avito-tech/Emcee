import AtomicModels
import DeveloperDirLocator
import Dispatch
import Foundation
import EmceeLogging
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolModels
import TestDestination

public final class SimctlBasedSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor, CustomStringConvertible {
    
    public struct SimctlUdidParseError: Error, CustomStringConvertible {
        public var description: String {
            "Simctl returned an empty udid value, or the value was not found"
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
        testDestination: AppleTestDestination,
        timeout: TimeInterval
    ) throws -> Simulator {
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
                    "create",
                    "Emcee Sim \(testDestination.deviceTypeForMetrics) \(testDestination.runtimeForMetrics)",
                    testDestination.simDeviceType,
                    testDestination.simRuntime,
                ],
                environment: Environment(environment),
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        
        var capturedData = Data()
        controller.onStdout { _, data, _ in capturedData.append(data) }
        try runAndHumanifyError(operation: .create, processController: controller)
        
        guard let createdUdid = String(data: capturedData, encoding: .utf8), !createdUdid.isEmpty else {
            throw SimctlUdidParseError()
        }
        let udid = UDID(value: createdUdid.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return Simulator(
            testDestination: testDestination,
            udid: udid,
            path: simulatorSetPath.appending(udid.value)
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
                environment: Environment(environment),
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try runAndHumanifyError(operation: .bootstatus, processController: processController)
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
                environment: Environment(environment),
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try runAndHumanifyError(operation: .shutdown, processController: shutdownController)
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
                environment: Environment(environment),
                automaticManagement: .sigintThenKillAfterRunningFor(interval: timeout)
            )
        )
        try runAndHumanifyError(operation: .delete, processController: deleteController)
    }
    
    public struct SimctlFailureError: Error, CustomStringConvertible {
        public enum Operation: String {
            case create
            case bootstatus
            case shutdown
            case delete
        }
        
        public let data: Data
        public let operation: Operation
        public let subprocess: Subprocess
        public let innerError: Error
        
        public var description: String {
            let processOutput = String(data: data, encoding: .utf8) ?? "non-utf8 output"
            return "Simctl failed to perform '\(operation.rawValue)' operation with error: \(innerError). Subprocess \(subprocess) had output: \(processOutput)"
        }
    }
    
    private func runAndHumanifyError(
        operation: SimctlFailureError.Operation,
        processController: ProcessController
    ) throws {
        let collectedOutput = AtomicValue(Data())
        processController.onStdout { _, data, _ in collectedOutput.withExclusiveAccess { $0.append(data) } }
        processController.onStderr { _, data, _ in collectedOutput.withExclusiveAccess { $0.append(data) } }
        
        do {
            try processController.startAndWaitForSuccessfulTermination()
        } catch {
            throw SimctlFailureError(data: collectedOutput.currentValue(), operation: operation, subprocess: processController.subprocess, innerError: error)
        }
    }
}
