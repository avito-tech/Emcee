import DeveloperDirModels
import Dispatch
import Foundation
import EmceeLogging
import ResourceLocationResolver
import RunnerModels
import SimulatorPoolModels
import TestDestination
import Tmp

public final class DefaultSimulatorPool: SimulatorPool, CustomStringConvertible {
    private let developerDir: DeveloperDir
    private let logger: ContextualLogger
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let tempFolder: TemporaryFolder
    private let testDestination: AppleTestDestination
    private var controllers = [SimulatorController]()
    private let syncQueue = DispatchQueue(label: "DefaultSimulatorPool.syncQueue")
    
    public var description: String {
        return "<\(type(of: self)): '\(testDestination.deviceTypeForMetrics)'+'\(testDestination.runtimeForMetrics)'>"
    }
    
    public init(
        developerDir: DeveloperDir,
        logger: ContextualLogger,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder,
        testDestination: AppleTestDestination
    ) throws {
        self.developerDir = developerDir
        self.logger = logger
        self.simulatorControllerProvider = simulatorControllerProvider
        self.tempFolder = tempFolder
        self.testDestination = testDestination
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
                temporaryFolder: tempFolder,
                testDestination: testDestination
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
