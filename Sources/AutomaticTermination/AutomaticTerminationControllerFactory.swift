import Foundation

public final class AutomaticTerminationControllerFactory {
    private let automaticTerminationPolicy: AutomaticTerminationPolicy

    public init(automaticTerminationPolicy: AutomaticTerminationPolicy) {
        self.automaticTerminationPolicy = automaticTerminationPolicy
    }
    
    public func createAutomaticTerminationController() -> AutomaticTerminationController {
        switch automaticTerminationPolicy {
        case .after(let timeInterval):
            return AfterFixedPeriodOfTimeTerminationController(
                dateProvider: DefaultDateProvider(),
                fireAt: Date().addingTimeInterval(timeInterval)
            )
        case .afterBeingIdle(let period):
            return AfterPeriodOfInactivityTerminationController(
                dateProvider: DefaultDateProvider(),
                inactivityInterval: period
            )
        case .stayAlive:
            return StayAliveTerminationController()
        }
    }
}
