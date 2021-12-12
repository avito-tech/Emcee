import AutomaticTermination
import Foundation
import EmceeLogging
import SimulatorPoolModels

public final class ActivityAwareSimulatorController: SimulatorController, CustomStringConvertible {
    private var automaticShutdownTerminationControllerFactory: AutomaticTerminationControllerFactory
    private var automaticShutdownController: AutomaticTerminationController?
    
    private var automaticDeletionTerminationControllerFactory: AutomaticTerminationControllerFactory
    private var automaticDeletionController: AutomaticTerminationController?
    
    private let delegate: SimulatorController
    
    private let logger: ContextualLogger
    
    /// - Parameters:
    ///   - automaticDeleteTimePeriod: Time after which simulator will be automatically deleted. Timer will start after simulator is shutdown.
    ///   - automaticShutdownTimePeriod: Time after which simulator will be automatically shutdown. Timer will start after simulator becomes idle.
    ///   - delegate: Simulator controller to manipulate
    public init(
        automaticDeleteTimePeriod: TimeInterval,
        automaticShutdownTimePeriod: TimeInterval,
        delegate: SimulatorController,
        logger: ContextualLogger
    ) {
        automaticDeletionTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: automaticDeleteTimePeriod
        )
        automaticShutdownTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: automaticShutdownTimePeriod
        )
        self.delegate = delegate
        self.logger = logger
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
    
    public var description: String {
        return "\(type(of: self)) delegate: \(delegate)"
    }
    
    // MARK: - Scheduling Automatic Operations
    
    private func scheduleAutomaticShutdown() {
        guard automaticShutdownController == nil else { return }
        
        automaticShutdownController = automaticShutdownTerminationControllerFactory.createAutomaticTerminationController()
        automaticShutdownController?.startTracking()
        automaticShutdownController?.add { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.logger.trace("Performing automatic shutdown of \(strongSelf.delegate)")
            try? strongSelf.shutdownSimulator()
        }
        logger.trace("Scheduled automatic shutdown of \(delegate)")
    }
    
    private func scheduleAutomaticDeletion() {
        guard automaticDeletionController == nil else { return }
        
        automaticDeletionController = automaticDeletionTerminationControllerFactory.createAutomaticTerminationController()
        automaticDeletionController?.startTracking()
        automaticDeletionController?.add { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.logger.trace("Performing automatic deletion of \(strongSelf.delegate)")
            try? strongSelf.deleteSimulator()
        }
        logger.trace("Scheduled automatic deletion of \(delegate)")
    }
    
    // MARK: - Cancelling Automatic Operations
    
    private func cancelAutomaticOperations() {
        cancelAutomaticShutdown()
        cancelAutomaticDelete()
    }
    
    private func cancelAutomaticShutdown() {
        if automaticShutdownController != nil {
            automaticShutdownController = nil
            logger.trace("Cancelled automatic shutdown of \(delegate)")
        }
    }
    
    private func cancelAutomaticDelete() {
        if automaticDeletionController != nil {
            automaticDeletionController = nil
            logger.trace("Cancelled automatic deletion of \(delegate)")
        }
    }
}
