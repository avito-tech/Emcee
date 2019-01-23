import Dispatch
import Foundation
import Timer

internal final class AfterFixedPeriodOfTimeTerminationController: AutomaticTerminationController {
    private let dateProvider: DateProvider
    private let fireAt: Date
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.AfterFixedPeriodOfTimeTerminationController.syncQueue")
    private var handlers = [AutomaticTerminationControllerHandler]()
    
    public init(dateProvider: DateProvider, fireAt: Date) {
        self.dateProvider = dateProvider
        self.fireAt = fireAt
    }
    
    func startTracking() {
        _ = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) { timer in
            if self.isTerminationAllowed {
                self.fireHandlers()
                timer.stop()
            }
        }
    }
    
    func add(handler: @escaping AutomaticTerminationControllerHandler) {
        syncQueue.sync {
            handlers.append(handler)
        }
    }
    
    func indicateActivityFinished() {}
    
    var isTerminationAllowed: Bool {
        return fireAt < dateProvider.currentDate()
    }
    
    private func fireHandlers() {
        let handlers = syncQueue.sync { self.handlers }
        for handler in handlers {
            handler()
        }
    }
}
