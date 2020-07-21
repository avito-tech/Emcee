import DeveloperDirLocator
import Foundation
import Logging
import PathLib
import ProcessController
import ResourceLocation
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolModels

public final class FbsimctlBasedSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor, CustomStringConvertible {
    private let fbsimctl: ResolvableResourceLocation
    private let processControllerProvider: ProcessControllerProvider
    private let simulatorsContainerPath: AbsolutePath
    private var simulatorKeepAliveProcessController: ProcessController?

    public init(
        fbsimctl: ResolvableResourceLocation,
        processControllerProvider: ProcessControllerProvider,
        simulatorsContainerPath: AbsolutePath
    ) {
        self.fbsimctl = fbsimctl
        self.processControllerProvider = processControllerProvider
        self.simulatorsContainerPath = simulatorsContainerPath
    }

    public func performCreateSimulatorAction(
        environment: [String : String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws -> Simulator {
        let setPath = simulatorsContainerPath.appending(
            components: [testDestination.deviceType.removingWhitespaces(), testDestination.runtime]
        )
        try FileManager.default.createDirectory(atPath: setPath)
        
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", setPath,
                    "create",
                    "iOS \(testDestination.runtime)", testDestination.deviceType
                ],
                environment: environment
            )
        )

        let fbsimctlEvents = try waitForFbsimctlToCreateSimulator(
            processController: processController,
            timeout: timeout
        )
        let createEndedEvents = fbsimctlEvents.compactMap { $0 as? FbSimCtlCreateEndedEvent }
        guard createEndedEvents.count == 1, let createEndedEvent = createEndedEvents.first else {
            throw FbsimctlError.createOperationFailed("Failed to get single create ended event")
        }
        
        let simulatorPath = setPath.appending(component: createEndedEvent.subject.udid.value)
        Logger.debug("Created new simulator \(createEndedEvent.subject.udid) at \(simulatorPath)")
        
        return Simulator(
            testDestination: testDestination,
            udid: createEndedEvent.subject.udid,
            path: simulatorPath
        )
    }
    
    public func performBootSimulatorAction(
        environment: [String : String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulator.simulatorSetPath,
                    simulator.udid.value, "boot",
                    "--locale", "ru_US",
                    "--direct-launch", "--", "listen"
                ],
                environment: environment
            )
        )
        try waitForFbsimctlToBootSimulator(
            processController: processController,
            timeout: timeout
        )

        // process should be alive at this point and the boot should have finished
        guard processController.isProcessRunning == true else {
            throw FbsimctlError.bootOperationFailed("Simulator keep-alive process died unexpectedly")
        }

        // we keep this process alive throughout the run, as it owns the simulator process.
        simulatorKeepAliveProcessController = processController
    }
    
    public func performShutdownSimulatorAction(
        environment: [String : String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil

        let shutdownController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl", "--set", simulator.simulatorSetPath,
                    "shutdown", simulator.udid.value
                ],
                environment: environment,
                automaticManagement: .sigintThenKillIfSilent(interval: timeout)
            )
        )
        shutdownController.startAndListenUntilProcessDies()
    }
    
    public func performDeleteSimulatorAction(
        environment: [String : String],
        simulator: Simulator,
        timeout: TimeInterval
    ) throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil
        
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulator.simulatorSetPath,
                    "--simulators", "delete"
                ],
                environment: environment,
                automaticManagement: .sigintThenKillIfSilent(interval: timeout)
            )
        )
        controller.startAndListenUntilProcessDies()
        
        try deleteSimulatorSetContainer(simulatorSetPath: simulator.simulatorSetPath)
    }
    
    private func deleteSimulatorSetContainer(
        simulatorSetPath: AbsolutePath
    ) throws {
        if FileManager.default.fileExists(atPath: simulatorSetPath.pathString) {
            Logger.verboseDebug("Removing simulator's container path \(simulatorSetPath)")
            try FileManager.default.removeItem(atPath: simulatorSetPath.pathString)
        }
    }

    // MARK: - Utility Methods

    private func waitForFbsimctlToCreateSimulator(
        processController: ProcessController,
        timeout: TimeInterval
    ) throws -> [FbSimCtlEventCommonFields] {
        let outputProcessor = FbsimctlOutputProcessor(processController: processController)
        return try outputProcessor.waitForEvent(type: .ended, name: .create, timeout: timeout)
    }

    private func waitForFbsimctlToBootSimulator(
        processController: ProcessController,
        timeout: TimeInterval
    ) throws {
        let outputProcessor = FbsimctlOutputProcessor(processController: processController)
        try outputProcessor.waitForEvent(type: .started, name: .listen, timeout: timeout)
    }

    public var description: String {
        return "fbsimctl"
    }
    
    private var fbsimctlArg: SubprocessArgument {
        return fbsimctl.asArgumentWith(implicitFilenameInArchive: "fbsimctl")
    }

    // MARK: - Errors

    private enum FbsimctlError: Error, CustomStringConvertible {
        case createOperationFailed(String)
        case bootOperationFailed(String)

        var description: String {
            switch self {
            case .createOperationFailed(let message):
                return "Failed to create simulator: \(message)"
            case .bootOperationFailed(let message):
                return "Failed to boot simulator: \(message)"
            }
        }
    }
}
