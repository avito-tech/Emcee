import Basic
import Dispatch
import Foundation
import Extensions
import Logging
import Models
import TempFolder
import ResourceLocationResolver

/**
 * Every 'borrow' must have a corresponding 'free' call, otherwise the next borrow will throw an error.
 * There is no blocking mechanisms, the assumption is that the callers will use up to numberOfSimulators of threads
 * to borrow and free the simulators.
 */
public class SimulatorPool<T>: CustomStringConvertible where T: SimulatorController {
    private let numberOfSimulators: UInt
    private let testDestination: TestDestination
    private var controllers: OrderedSet<T>
    private var automaticCleanupWorkItem: DispatchWorkItem?
    private let automaticCleanupTiumeout: TimeInterval
    private let syncQueue = DispatchQueue(label: "ru.avito.SimulatorPool")
    private let cleanUpQueue = DispatchQueue(label: "ru.avito.SimulatorPool.cleanup")
    
    public var description: String {
        return "<\(type(of: self)): \(numberOfSimulators)-sim '\(testDestination.deviceType)'+'\(testDestination.runtime)'>"
    }
    
    public init(
        numberOfSimulators: UInt,
        testDestination: TestDestination,
        fbsimctl: ResolvableResourceLocation,
        tempFolder: TempFolder,
        automaticCleanupTiumeout: TimeInterval = 10) throws
    {
        self.numberOfSimulators = numberOfSimulators
        self.testDestination = testDestination
        self.automaticCleanupTiumeout = automaticCleanupTiumeout
        controllers = try SimulatorPool.createControllers(
            count: numberOfSimulators,
            testDestination: testDestination,
            fbsimctl: fbsimctl,
            tempFolder: tempFolder)
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func allocateSimulator() throws -> T {
        return try syncQueue.sync {
            guard controllers.count > 0 else {
                throw BorrowError.noSimulatorsLeft
            }
            let simulator = controllers.removeLast()
            Logger.verboseDebug("Allocated simulator: \(simulator)")
            cancelAutomaticCleanup()
            return simulator
        }
    }
    
    public func freeSimulator(_ simulator: T) {
        syncQueue.sync {
            controllers.append(simulator)
            Logger.verboseDebug("Freed simulator: \(simulator)")
            scheduleAutomaticCleanup()
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            cancelAutomaticCleanup()
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
    
    private static func createControllers(
        count: UInt,
        testDestination: TestDestination,
        fbsimctl: ResolvableResourceLocation,
        tempFolder: TempFolder) throws -> OrderedSet<T>
    {
        var result = OrderedSet<T>()
        for index in 0 ..< count {
            let folderName = "sim_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.runtime)_\(index)"
            let workingDirectory = try tempFolder.pathByCreatingDirectories(components: [folderName])
            let simulator = Simulator(index: index, testDestination: testDestination, workingDirectory: workingDirectory)
            let controller = T(simulator: simulator, fbsimctl: fbsimctl)
            result.append(controller)
        }
        return result
    }
    
    private func cancelAutomaticCleanup() {
        automaticCleanupWorkItem?.cancel()
        automaticCleanupWorkItem = nil
    }
    
    private func scheduleAutomaticCleanup() {
        cancelAutomaticCleanup()
        
        let cancellationWorkItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.automaticCleanupWorkItem = nil
            if strongSelf.controllers.count == strongSelf.numberOfSimulators {
                Logger.debug("Simulator controllers were not in use for \(strongSelf.automaticCleanupTiumeout) seconds.")
                strongSelf.deleteSimulators()
            }
        }
        cleanUpQueue.asyncAfter(deadline: .now() + automaticCleanupTiumeout, execute: cancellationWorkItem)
        self.automaticCleanupWorkItem = cancellationWorkItem
    }
}
