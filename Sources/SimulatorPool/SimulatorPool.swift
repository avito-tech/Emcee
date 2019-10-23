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
    private let numberOfSimulators: UInt
    private let testDestination: TestDestination
    private var controllers: [SimulatorController]
    private let syncQueue = DispatchQueue(label: "ru.avito.SimulatorPool")
    
    public var description: String {
        return "<\(type(of: self)): \(numberOfSimulators)-sim '\(testDestination.deviceType)'+'\(testDestination.runtime)'>"
    }
    
    public init(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        numberOfSimulators: UInt,
        simulatorControlTool: SimulatorControlTool,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder,
        testDestination: TestDestination
    ) throws {
        self.numberOfSimulators = numberOfSimulators
        self.testDestination = testDestination
        controllers = try SimulatorPool.createControllers(
            count: numberOfSimulators,
            developerDir: developerDir,
            developerDirLocator: developerDirLocator,
            simulatorControlTool: simulatorControlTool,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder,
            testDestination: testDestination
        )
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func allocateSimulatorController() throws -> SimulatorController {
        return try syncQueue.sync {
            guard let simulator = controllers.popLast() else {
                throw BorrowError.noSimulatorsLeft
            }
            Logger.verboseDebug("Allocated simulator: \(simulator)")
            return simulator
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
    
    private static func createControllers(
        count: UInt,
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulatorControlTool: SimulatorControlTool,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder,
        testDestination: TestDestination
    ) throws -> [SimulatorController] {
        var result = [SimulatorController]()
        for index in 0 ..< count {
            let folderName = "sim_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.runtime)_\(index)"
            let workingDirectory = try tempFolder.pathByCreatingDirectories(components: [folderName])
            let simulator = Simulator(testDestination: testDestination, workingDirectory: workingDirectory)
            let controller = try simulatorControllerProvider.createSimulatorController(
                developerDir: developerDir,
                developerDirLocator: developerDirLocator,
                simulator: simulator,
                simulatorControlTool: simulatorControlTool
            )
            result.append(controller)
        }
        return result
    }
}
