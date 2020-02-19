import AutomaticTermination
import Foundation
import Logging
import SimulatorPoolModels

public final class ActivityAwareSimulatorController: SimulatorController {
    private var automaticTerminationControllerFactory: AutomaticTerminationControllerFactory
    private var automaticShutdownController: AutomaticTerminationController?
    private let delegate: SimulatorController

    public init(
        automaticShutdownTimePeriod: TimeInterval,
        delegate: SimulatorController
    ) {
        automaticTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
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
        
        automaticTerminationControllerFactory = ActivityAwareSimulatorController.automaticTerminationController(
            period: simulatorOperationTimeouts.automaticSimulatorShutdown
        )
    }
    
    public func bootedSimulator() throws -> Simulator {
        return try delegate.bootedSimulator()
    }
    
    public func deleteSimulator() throws {
        cancelAutomaticShutdown()
        try delegate.deleteSimulator()
    }
    
    public func shutdownSimulator() throws {
        cancelAutomaticShutdown()
        try delegate.shutdownSimulator()
    }
    
    public func simulatorBecameBusy() {
        cancelAutomaticShutdown()
        delegate.simulatorBecameBusy()
    }
    
    public func simulatorBecameIdle() {
        scheduleAutomaticShutdown()
        delegate.simulatorBecameIdle()
    }
    
    private func scheduleAutomaticShutdown() {
        guard automaticShutdownController == nil else {
            Logger.debug("Automatic shutdown of \(delegate) has already been scheduled")
            return
        }
        
        automaticShutdownController = automaticTerminationControllerFactory.createAutomaticTerminationController()
        automaticShutdownController?.startTracking()
        automaticShutdownController?.add { [weak self] in
            guard let strongSelf = self else { return }
            Logger.debug("Performing automatic shutdown of \(strongSelf.delegate)")
            try? strongSelf.shutdownSimulator()
        }
        Logger.debug("Scheduled automatic shutdown of \(delegate)")
    }
    
    private func cancelAutomaticShutdown() {
        if automaticShutdownController == nil {
            Logger.debug("Automatic shutdown of \(delegate) has already been cancelled")
        } else {
            automaticShutdownController = nil
            Logger.debug("Cancelled automatic shutdown of \(delegate)")
        }
    }
}
