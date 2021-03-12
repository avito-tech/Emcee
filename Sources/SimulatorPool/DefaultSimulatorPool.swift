import DeveloperDirModels
import Dispatch
import Foundation
import EmceeLogging
import ResourceLocationResolver
import RunnerModels
import SimulatorPoolModels
import Tmp

public final class DefaultSimulatorPool: SimulatorPool, CustomStringConvertible {
    private let developerDir: DeveloperDir
    private let logger: ContextualLogger
    private let simulatorControlTool: SimulatorControlTool
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let tempFolder: TemporaryFolder
    private let testDestination: TestDestination
    private var controllers = [SimulatorController]()
    private let syncQueue = DispatchQueue(label: "DefaultSimulatorPool.syncQueue")
    
    public var description: String {
        return "<\(type(of: self)): '\(testDestination.deviceType)'+'\(testDestination.runtime)'>"
    }
    
    public init(
        developerDir: DeveloperDir,
        logger: ContextualLogger,
        simulatorControlTool: SimulatorControlTool,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder,
        testDestination: TestDestination
    ) throws {
        self.developerDir = developerDir
        self.logger = logger.forType(Self.self)
        self.simulatorControlTool = simulatorControlTool
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
                logger.debug("Allocated simulator: \(controller)")
                controller.simulatorBecameBusy()
                return controller
            }
            let controller = try simulatorControllerProvider.createSimulatorController(
                developerDir: developerDir,
                simulatorControlTool: simulatorControlTool,
                temporaryFolder: tempFolder,
                testDestination: testDestination
            )
            logger.debug("Allocated new simulator: \(controller)")
            controller.simulatorBecameBusy()
            return controller
        }
    }
    
    public func free(simulatorController: SimulatorController) {
        syncQueue.sync {
            controllers.append(simulatorController)
            logger.debug("Freed simulator: \(simulatorController)")
            simulatorController.simulatorBecameIdle()
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            logger.debug("\(self): deleting simulators")
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
            logger.debug("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.shutdownSimulator()
                } catch {
                    logger.warning("Failed to shutdown simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
    
    internal func numberExistingOfControllers() -> Int {
        return syncQueue.sync { controllers.count }
    }
}
