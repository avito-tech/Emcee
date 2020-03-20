import AutomaticTermination
import Foundation
import Logging
import SimulatorPoolModels

public final class ActivityAwareSimulatorController: SimulatorController {
    private var automaticShutdownTerminationControllerFactory: AutomaticTerminationControllerFactory
    private var automaticShutdownController: AutomaticTerminationController?
    
    private var automaticDeletionTerminationControllerFactory: AutomaticTerminationControllerFactory
    private var automaticDeletionController: AutomaticTerminationController?
    
    private let delegate: SimulatorController
    
    /// - Parameters:
    ///   - automaticDeleteTimePeriod: Time after which simulator will be automatically deleted. Timer will start after simulator is shutdown.
    ///   - automaticShutdownTimePeriod: Time after which simulator will be automatically shutdown. Timer will start after simulator becomes idle.
    ///   - delegate: Simulator controller to manipulate
    public init(
        automaticDeleteTimePeriod: TimeInterval,
        automaticShutdownTimePeriod: TimeInterval,
        delegate: SimulatorController
    ) {
        automaticDeletionTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: automaticDeleteTimePeriod
        )
        automaticShutdownTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: automaticShutdownTimePeriod
        )
        self.delegate = delegate
    }
    
    private static func automaticTerminationController(period: TimeInterval) -> AutomaticTerminationControllerFactory {
        return AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: .afterBeingIdle(period: period)
        )
    }
    
    public func apply(simulatorOperationTimeouts: SimulatorOperationTimeouts) {
        delegate.apply(simulatorOperationTimeouts: simulatorOperationTimeouts)
        
        automaticDeletionTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: simulatorOperationTimeouts.automaticSimulatorDelete
        )
        automaticShutdownTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: simulatorOperationTimeouts.automaticSimulatorShutdown
        )
    }
    
    public func bootedSimulator() throws -> Simulator {
        return try delegate.bootedSimulator()
    }
    
    public func deleteSimulator() throws {
        cancelAutomaticOperations()
        try delegate.deleteSimulator()
    }
    
    public func shutdownSimulator() throws {
        cancelAutomaticShutdown()
        try delegate.shutdownSimulator()
        scheduleAutomaticDeletion()
    }
    
    public func simulatorBecameBusy() {
        cancelAutomaticOperations()
        delegate.simulatorBecameBusy()
    }
    
    public func simulatorBecameIdle() {
        scheduleAutomaticShutdown()
        delegate.simulatorBecameIdle()
    }
    
    // MARK: - Scheduling Automatic Operations
    
    private func scheduleAutomaticShutdown() {
        guard automaticShutdownController == nil else {
            Logger.debug("Automatic shutdown of \(delegate) has already been scheduled")
            return
        }
        
        automaticShutdownController = automaticShutdownTerminationControllerFactory.createAutomaticTerminationController()
        automaticShutdownController?.startTracking()
        automaticShutdownController?.add { [weak self] in
            guard let strongSelf = self else { return }
            Logger.debug("Performing automatic shutdown of \(strongSelf.delegate)")
            try? strongSelf.shutdownSimulator()
        }
        Logger.debug("Scheduled automatic shutdown of \(delegate)")
    }
    
    private func scheduleAutomaticDeletion() {
        guard automaticDeletionController == nil else {
            Logger.debug("Automatic deletion of \(delegate) has already been scheduled")
            return
        }
        
        automaticDeletionController = automaticDeletionTerminationControllerFactory.createAutomaticTerminationController()
        automaticDeletionController?.startTracking()
        automaticDeletionController?.add { [weak self] in
            guard let strongSelf = self else { return }
            Logger.debug("Performing automatic deletion of \(strongSelf.delegate)")
            try? strongSelf.deleteSimulator()
        }
        Logger.debug("Scheduled automatic deletion of \(delegate)")
    }
    
    // MARK: - Cancelling Automatic Operations
    
    private func cancelAutomaticOperations() {
        cancelAutomaticShutdown()
        cancelAutomaticDelete()
    }
    
    private func cancelAutomaticShutdown() {
        if automaticShutdownController == nil {
            Logger.debug("Automatic shutdown of \(delegate) has already been cancelled")
        } else {
            automaticShutdownController = nil
            Logger.debug("Cancelled automatic shutdown of \(delegate)")
        }
    }
    
    private func cancelAutomaticDelete() {
        if automaticDeletionController == nil {
            Logger.debug("Automatic deletion of \(delegate) has already been cancelled")
        } else {
            automaticDeletionController = nil
            Logger.debug("Cancelled automatic deletion of \(delegate)")
        }
    }
}
