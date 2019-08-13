import DateProvider
import Foundation

internal final class AfterPeriodOfInactivityTerminationController: BaseAutomaticTerminationController {
    private let inactivityInterval: TimeInterval
    
    public init(dateProvider: DateProvider, inactivityInterval: TimeInterval) {
        self.inactivityInterval = inactivityInterval
        super.init(dateProvider: dateProvider)
    }
    
    override var isTerminationAllowed: Bool {
        return dateProvider.currentDate() > lastActivityDate.addingTimeInterval(inactivityInterval)
    }
}
