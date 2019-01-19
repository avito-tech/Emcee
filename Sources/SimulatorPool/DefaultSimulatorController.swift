import Dispatch
import Foundation
import Logging
import Models
import fbxctest
import ProcessController
import ResourceLocationResolver

/**
 * Prepares and returns the simulator it owns. API is expected to be used from non multithreaded environment,
 * i.e. from serial queue.
 */
public final class DefaultSimulatorController: SimulatorController, ProcessControllerDelegate, CustomStringConvertible {
    private let simulator: Simulator
    private let fbsimctl: ResolvableResourceLocation
    private let maximumBootAttempts = 2
    private var stage: Stage = .idle
    private var simulatorKeepAliveProcessController: ProcessController?
    private static let bootQueue = DispatchQueue(label: "SimulatorBootQueue")
    
    public init(simulator: Simulator, fbsimctl: ResolvableResourceLocation) {
        self.simulator = simulator
        self.fbsimctl = fbsimctl
    }
    
    /**
     * This method prepares the simulator and returns it. It must be called from the serial queue.
     * Two parallel calls in case if the simulator is being created and booted will throw an error.
     * If creation or booting fails, this method will also throw an error.
     */
    public func bootedSimulator() throws -> Simulator {
        if stage == .bootedSimulator {
            return simulator
        }
        
        guard stage == .idle else {
            Logger.error("Simulator \(simulator) is already being booted")
            throw SimulatorBootError.bootingAlreadyStarted
        }
        
        return try bootRetryingOnFailure()
    }
    
    private func bootRetryingOnFailure() throws -> Simulator {
        return try DefaultSimulatorController.bootQueue.sync {
            var bootAttempt = 0
            while true {
                do {
                    try createAndBoot()
                    Logger.debug("Booted simulator \(simulator) using #\(bootAttempt + 1) attempts")
                    return simulator
                } catch {
                    Logger.error("Attempt #\(bootAttempt) to boot simulator \(simulator) failed: \(error)")
                    try deleteSimulator()
                    bootAttempt += 1
                    if bootAttempt < maximumBootAttempts {
                        let waitBetweenAttemptsToBoot = 5.0
                        Logger.warning("Waiting \(waitBetweenAttemptsToBoot) seconds before attempting to boot again")
                        Thread.sleep(forTimeInterval: waitBetweenAttemptsToBoot)
                    } else {
                        throw error
                    }
                }
            }
        }
    }
    
    private func createAndBoot() throws {
        try createSimulator()
        try bootSimulator()
    }
    
    private func createSimulator() throws {
        guard stage == .idle else {
            throw SimulatorBootError.bootingAlreadyStarted
        }
        
        stage = .creatingSimulator
        Logger.verboseDebug("Creating simulator: \(simulator)")
        let simulatorSetPath = simulator.fbxctestContainerPath.asString
        try FileManager.default.createDirectory(atPath: simulatorSetPath, withIntermediateDirectories: true)
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctl.asArgumentWith(packageName: PackageName.fbsimctl),
                    "--json", "--set", simulatorSetPath,
                    "create", "iOS \(simulator.testDestination.runtime)", simulator.testDestination.deviceType],
                maximumAllowedSilenceDuration: 30))
        controller.delegate = self
        controller.startAndListenUntilProcessDies()
        
        guard stage == .creatingSimulator else { throw SimulatorBootError.createOperationFailed("Unexpected stage \(stage)") }
        guard controller.terminationStatus() == 0 else {
            throw SimulatorBootError.createOperationFailed("fbsimctl exit code \(String(describing: controller.terminationStatus()))")
        }
        stage = .createdSimulator
        Logger.debug("Created simulator")
    }

    private func bootSimulator() throws {
        guard stage == .createdSimulator else {
            throw SimulatorBootError.bootingAlreadyStarted
        }
        
        let containerContents = try FileManager.default.contentsOfDirectory(atPath: simulator.fbxctestContainerPath.asString)
        let simulatorUuids = containerContents.filter { UUID(uuidString: $0) != nil }
        guard simulatorUuids.count > 0, let simulatorUuid = simulatorUuids.first else {
            throw SimulatorBootError.unableToLocateSimulatorUuid
        }
        
        stage = .bootingSimulator
        Logger.verboseDebug("Booting simulator: \(simulator)")
        
        // we keep this process alive throughout the run, as it owns the simulator process.
        simulatorKeepAliveProcessController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctl.asArgumentWith(packageName: PackageName.fbsimctl),
                    "--json", "--set", simulator.fbxctestContainerPath.asString,
                    simulatorUuid, "boot",
                    "--locale", "ru_US",
                    "--direct-launch", "--", "listen"]))
        
        try waitForSimulatorBoot()
        
        // process should be alive at this point and the boot should have finished
        guard stage == .bootingSimulator else { throw SimulatorBootError.bootOperationFailed("Unexpected stage \(stage)") }
        guard simulatorKeepAliveProcessController?.isProcessRunning == true else {
            throw SimulatorBootError.bootOperationFailed("Simulator keep-alive process died unexpectedly")
        }
        stage = .bootedSimulator
        Logger.debug("Booted simulator: \(simulator)")
    }
    
    private func waitForSimulatorBoot() throws {
        guard let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController else {
            Logger.error("Expected to have keep-alive process")
            throw SimulatorBootError.bootOperationFailed("No keep-alive process found")
        }
        let outputProcessor = FbsimctlOutputProcessor(processController: simulatorKeepAliveProcessController)
        do {
            try outputProcessor.waitForEvent(type: .ended, name: .boot, timeout: 90)
        } catch {
            Logger.error("Simulator \(simulator) did not boot in time: \(error)")
            throw error
        }
        
        do {
            try outputProcessor.waitForEvent(type: .started, name: .listen, timeout: 50)
        } catch {
            Logger.error("Boot operation for simulator \(simulator) did not finish: \(error)")
            throw error
        }
    }
    
    public func deleteSimulator() throws {
        simulatorKeepAliveProcessController?.interruptAndForceKillIfNeeded()
        simulatorKeepAliveProcessController = nil
        
        if stage == .idle {
            Logger.debug("Simulator \(simulator) hasn't booted yet, so it won't be deleted.")
            return
        }
        
        stage = .deletingSimulator
        
        Logger.verboseDebug("Deleting simulator: \(simulator)")
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctl.asArgumentWith(packageName: PackageName.fbsimctl),
                    "--json", "--set", simulator.fbxctestContainerPath.asString,
                    "--simulators", "delete"],
                maximumAllowedSilenceDuration: 90))
        controller.delegate = self
        controller.startAndListenUntilProcessDies()
        
        guard stage == .deletingSimulator else { throw SimulatorBootError.deleteOperationFailed("Unexpected stage: \(stage)") }
        guard controller.terminationStatus() == 0 else {
            throw SimulatorBootError.deleteOperationFailed("Unexpected fbsimctl exit code: \(String(describing: controller.terminationStatus()))")
        }
        stage = .idle
        Logger.debug("Deleted simulator: \(simulator)")
    }
    
    // MARK: - Process Controller Events
    
    public func processController(_ sender: ProcessController, newStdoutData data: Data) {}
    
    public func processController(_ sender: ProcessController, newStderrData data: Data) {}
    
    public func processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(_ sender: ProcessController) {
        if stage == .creatingSimulator {
            stage = .creationHang
        } else if stage == .bootingSimulator {
            stage = .bootHang
        } else if stage == .deletingSimulator {
            stage = .deleteHang
        }
        sender.interruptAndForceKillIfNeeded()
    }
    
    // MARK: - Protocols
    
    public var hashValue: Int {
        return simulator.hashValue
    }
    
    public static func == (l: DefaultSimulatorController, r: DefaultSimulatorController) -> Bool {
        return l.simulator == r.simulator
    }
    
    public var description: String {
        return "Controller for simulator \(simulator)"
    }
    
    // MARK: - States and State Errors
    
    private enum Stage: String, CustomStringConvertible {
        case idle
        case creatingSimulator
        case creationHang
        case createdSimulator
        case bootingSimulator
        case bootHang
        case bootedSimulator
        case deletingSimulator
        case deleteHang
        
        var description: String { return self.rawValue }
    }
    
    private enum SimulatorBootError: Error, CustomStringConvertible {
        case bootingAlreadyStarted
        case createOperationFailed(String)
        case unableToLocateSimulatorUuid
        case bootOperationFailed(String)
        case deleteOperationFailed(String)
        
        var description: String {
            switch self {
            case .bootingAlreadyStarted:
                return "Failed to boot simulator, flow violation: boot has already started"
            case .createOperationFailed(let message):
                return "Failed to create simulator: \(message)"
            case .unableToLocateSimulatorUuid:
                return "Failed to boot simulator: failed to locate simulator's UUID"
            case .bootOperationFailed(let message):
                return "Failed to boot simulator: \(message)"
            case .deleteOperationFailed(let message):
                return "Failed to delete simulator: \(message)"
            }
        }
    }
}
