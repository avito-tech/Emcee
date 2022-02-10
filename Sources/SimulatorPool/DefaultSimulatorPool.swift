import DeveloperDirModels
import Dispatch
import Foundation
import EmceeLogging
import ResourceLocationResolver
import SimulatorPoolModels
import Tmp

public final class DefaultSimulatorPool: SimulatorPool, CustomStringConvertible {
    private let developerDir: DeveloperDir
    private let logger: ContextualLogger
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let simDeviceType: SimDeviceType
    private let simRuntime: SimRuntime
    private let tempFolder: TemporaryFolder
    private var controllers = [SimulatorController]()
    private let syncQueue = DispatchQueue(label: "DefaultSimulatorPool.syncQueue")
    
    public var description: String {
        return "<\(type(of: self)): '\(simRuntime.shortForMetrics)'+'\(simDeviceType.shortForMetrics)'>"
    }
    
    public init(
        developerDir: DeveloperDir,
        logger: ContextualLogger,
        simulatorControllerProvider: SimulatorControllerProvider,
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
        tempFolder: TemporaryFolder
    ) {
        self.developerDir = developerDir
        self.logger = logger
        self.simulatorControllerProvider = simulatorControllerProvider
        self.simDeviceType = simDeviceType
        self.simRuntime = simRuntime
        self.tempFolder = tempFolder
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func allocateSimulatorController() throws -> SimulatorController {
        return try syncQueue.sync {
            if let controller = controllers.popLast() {
                logger.trace("Allocated simulator: \(controller)")
                controller.simulatorBecameBusy()
                return controller
            }
            let controller = try simulatorControllerProvider.createSimulatorController(
                developerDir: developerDir,
                simDeviceType: simDeviceType,
                simRuntime: simRuntime,
                temporaryFolder: tempFolder
            )
            logger.trace("Allocated new simulator: \(controller)")
            controller.simulatorBecameBusy()
            return controller
        }
    }
    
    public func free(simulatorController: SimulatorController) {
        syncQueue.sync {
            controllers.append(simulatorController)
            logger.trace("Freed simulator: \(simulatorController)")
            simulatorController.simulatorBecameIdle()
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            logger.trace("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.deleteSimulator()
                } catch {
                    logger.warning("Failed to delete simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
    
    public func shutdownSimulators() {
        syncQueue.sync {
            logger.trace("\(self): shutting down simulators")
            controllers.forEach {
                do {
                    try $0.shutdownSimulator()
                } catch {
                    logger.warning("Failed to shutdown simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
}
