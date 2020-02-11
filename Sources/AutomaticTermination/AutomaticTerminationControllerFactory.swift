import DateProvider
import Foundation

public final class AutomaticTerminationControllerFactory {
    private let automaticTerminationPolicy: AutomaticTerminationPolicy

    public init(automaticTerminationPolicy: AutomaticTerminationPolicy) {
        self.automaticTerminationPolicy = automaticTerminationPolicy
    }
    
    public func createAutomaticTerminationController() -> AutomaticTerminationController {
        switch automaticTerminationPolicy {
        case .afterBeingIdle(let period):
            return AfterPeriodOfInactivityTerminationController(
                dateProvider: SystemDateProvider(),
                inactivityInterval: period
            )
        case .stayAlive:
            return StayAliveTerminationController()
        }
    }
}
