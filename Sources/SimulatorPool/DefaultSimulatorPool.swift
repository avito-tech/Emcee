import DeveloperDirLocator
import Dispatch
import Extensions
import Foundation
import Logging
import Models
import ResourceLocationResolver
import TemporaryStuff

/**
 * Every 'borrow' must have a corresponding 'free' call, otherwise the next borrow will throw an error.
 * There is no blocking mechanisms, the assumption is that the callers will use up to numberOfSimulators of threads
 * to borrow and free the simulators.
 */
public final class DefaultSimulatorPool: SimulatorPool, CustomStringConvertible {
    private let developerDir: DeveloperDir
    private let developerDirLocator: DeveloperDirLocator
    private let simulatorControlTool: SimulatorControlTool
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let tempFolder: TemporaryFolder
    private let testDestination: TestDestination
    private let testRunnerTool: TestRunnerTool
    private var controllers = [SimulatorController]()
    private let syncQueue = DispatchQueue(label: "ru.avito.SimulatorPool")
    
    public var description: String {
        return "<\(type(of: self)): '\(testDestination.deviceType)'+'\(testDestination.runtime)'>"
    }
    
    public init(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulatorControlTool: SimulatorControlTool,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws {
        self.developerDir = developerDir
        self.developerDirLocator = developerDirLocator
        self.simulatorControlTool = simulatorControlTool
        self.simulatorControllerProvider = simulatorControllerProvider
        self.tempFolder = tempFolder
        self.testDestination = testDestination
        self.testRunnerTool = testRunnerTool
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func allocateSimulatorController() throws -> SimulatorController {
        return try syncQueue.sync {
            if let controller = controllers.popLast() {
                Logger.verboseDebug("Allocated simulator: \(controller)")
                return controller
            }
            let controller = try simulatorControllerProvider.createSimulatorController(
                developerDir: developerDir,
                developerDirLocator: developerDirLocator,
                simulatorControlTool: simulatorControlTool,
                testDestination: testDestination,
                testRunnerTool: testRunnerTool
            )
            Logger.verboseDebug("Allocated new simulator: \(controller)")
            return controller
        }
    }
    
    public func free(simulatorController: SimulatorController) {
        syncQueue.sync {
            controllers.append(simulatorController)
            Logger.verboseDebug("Freed simulator: \(simulatorController)")
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            Logger.verboseDebug("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.deleteSimulator()
                } catch {
                    Logger.warning("Failed to delete simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
    
    public func shutdownSimulators() {
        syncQueue.sync {
            Logger.verboseDebug("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.shutdownSimulator()
                } catch {
                    Logger.warning("Failed to shutdown simulator \($0): \(error). Skipping this error.")
                }
            }
        }
    }
    
    internal func numberExistingOfControllers() -> Int {
        return syncQueue.sync { controllers.count }
    }
}
