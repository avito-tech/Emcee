import Foundation
import Timer

internal final class AfterPeriodOfInactivityTerminationController: AutomaticTerminationController {
    private let dateProvider: DateProvider
    private let inactivityInterval: TimeInterval
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.AfterFixedPeriodOfTimeTerminationController.syncQueue")
    private var handlers = [AutomaticTerminationControllerHandler]()
    private var lastActivityDate: Date
    
    public init(dateProvider: DateProvider, inactivityInterval: TimeInterval) {
        self.dateProvider = dateProvider
        self.inactivityInterval = inactivityInterval
        self.lastActivityDate = dateProvider.currentDate()
    }
    
    var isTerminationAllowed: Bool {
        return dateProvider.currentDate() > lastActivityDate.addingTimeInterval(inactivityInterval)
    }
    
    func startTracking() {
        updateLastActivityDate()
        
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
    
    func indicateActivityFinished() {
        updateLastActivityDate()
    }
    
    private func updateLastActivityDate()  {
        syncQueue.sync {
            if !isTerminationAllowed {
                lastActivityDate = dateProvider.currentDate()
            }
        }
    }
    
    private func fireHandlers() {
        let handlers = syncQueue.sync { self.handlers }
        for handler in handlers {
            handler()
        }
    }
}
