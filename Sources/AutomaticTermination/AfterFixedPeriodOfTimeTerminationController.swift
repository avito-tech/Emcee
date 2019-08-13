import DateProvider
import Foundation

internal final class AfterFixedPeriodOfTimeTerminationController: BaseAutomaticTerminationController {
    private let fireAt: Date
    
    public init(dateProvider: DateProvider, fireAt: Date) {
        self.fireAt = fireAt
        super.init(dateProvider: dateProvider)
    }
    
    override var isTerminationAllowed: Bool {
        return fireAt < dateProvider.currentDate()
    }
}
