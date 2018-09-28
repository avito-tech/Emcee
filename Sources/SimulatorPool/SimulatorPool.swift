import Basic
import Dispatch
import Foundation
import Extensions
import Logging
import Models

/**
 * Every 'borrow' must have a corresponding 'free' call, otherwise the next borrow will throw an error.
 * There is no blocking mechanisms, the assumption is that the callers will use up to numberOfSimulators of threads
 * to borrow and free the simulators.
 */
public final class SimulatorPool<T>: CustomStringConvertible where T: SimulatorController {
    private let numberOfSimulators: UInt
    private let testDestination: TestDestination
    private var controllers: OrderedSet<T>
    private var automaticCleanupWorkItem: DispatchWorkItem?
    private let automaticCleanupTiumeout: TimeInterval
    private let syncQueue = DispatchQueue(label: "ru.avito.SimulatorPool")
    private let cleanUpQueue = DispatchQueue(label: "ru.avito.SimulatorPool.cleanup")
    
    public var description: String {
        return "<\(type(of: self)): \(numberOfSimulators)-sim '\(testDestination.deviceType)'+'\(testDestination.iOSVersion)'>"
    }
    
    public init(
        numberOfSimulators: UInt,
        testDestination: TestDestination,
        auxiliaryPaths: AuxiliaryPaths,
        automaticCleanupTiumeout: TimeInterval = 10)
    {
        self.numberOfSimulators = numberOfSimulators
        self.testDestination = testDestination
        self.automaticCleanupTiumeout = automaticCleanupTiumeout
        controllers = SimulatorPool.createControllers(
            count: numberOfSimulators,
            testDestination: testDestination,
            auxiliaryPaths: auxiliaryPaths)
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
            log("Allocated simulator: \(simulator)", color: .blue)
            cancelAutomaticCleanup()
            return simulator
        }
    }
    
    public func freeSimulator(_ simulator: T) {
        syncQueue.sync {
            controllers.append(simulator)
            log("Freed simulator: \(simulator)", color: .blue)
            scheduleAutomaticCleanup()
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            cancelAutomaticCleanup()
            log("\(self): deleting simulators")
            controllers.forEach {
                do {
                    try $0.deleteSimulator()
                } catch let error {
                    log("Failed to delete simulator \($0): \(error). Skipping this error.", color: .red)
                }
            }
        }
    }
    
    private static func createControllers(
        count: UInt,
        testDestination: TestDestination,
        auxiliaryPaths: AuxiliaryPaths) -> OrderedSet<T>
    {
        var result = OrderedSet<T>()
        for index in 0 ..< count {
            let folderName = "sim_\(testDestination.deviceType.removingWhitespaces())_\(testDestination.iOSVersion)_\(index)"
            let workingDirectory = auxiliaryPaths.tempFolder.appending(pathComponent: folderName)
            let simulator = Simulator(index: index, testDestination: testDestination, workingDirectory: workingDirectory)
            let controller = T(simulator: simulator, fbsimctlPath: auxiliaryPaths.fbsimctl)
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
                log("\(strongSelf): simulator controllers were not in use for \(strongSelf.automaticCleanupTiumeout) seconds.")
                strongSelf.deleteSimulators()
            }
        }
        cleanUpQueue.asyncAfter(deadline: .now() + automaticCleanupTiumeout, execute: cancellationWorkItem)
        self.automaticCleanupWorkItem = cancellationWorkItem
    }
}
