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
public class SimulatorPool: CustomStringConvertible {
    private let developerDir: DeveloperDir
    private let developerDirLocator: DeveloperDirLocator
    private let simulatorControlTool: SimulatorControlTool
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let tempFolder: TemporaryFolder
    private let testDestination: TestDestination
    private var controllers = [SimulatorController]()
    private var allocationCounter = 0
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
        testDestination: TestDestination
    ) throws {
        self.developerDir = developerDir
        self.developerDirLocator = developerDirLocator
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
                Logger.verboseDebug("Allocated simulator: \(controller)")
                return controller
            }
            
            let folderName = "sim_\(allocationCounter)_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.runtime)"
            let workingDirectory = try tempFolder.pathByCreatingDirectories(components: [folderName])
            let simulator = Simulator(testDestination: testDestination, workingDirectory: workingDirectory)
            let controller = try simulatorControllerProvider.createSimulatorController(
                developerDir: developerDir,
                developerDirLocator: developerDirLocator,
                simulator: simulator,
                simulatorControlTool: simulatorControlTool
            )
            Logger.verboseDebug("Allocated new simulator (\(allocationCounter)-th): \(controller)")
            allocationCounter += 1
            return controller
        }
    }
    
    public func freeSimulatorController(_ simulator: SimulatorController) {
        syncQueue.sync {
            controllers.append(simulator)
            Logger.verboseDebug("Freed simulator: \(simulator)")
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
