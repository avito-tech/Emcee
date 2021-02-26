import DateProvider
import Dispatch
import Foundation
import Logging
import Timer

internal class BaseAutomaticTerminationController: AutomaticTerminationController {
    internal let dateProvider: DateProvider
    private var storedActivityDate: Date
    private var handlers = [AutomaticTerminationControllerHandler]()
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.BaseAutomaticTerminationController.syncQueue")
    private var trackingTimer = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(1))
    
    init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
        storedActivityDate = dateProvider.currentDate()
    }
    
    var isTerminationAllowed: Bool {
        fatalError("Subclasses must override this method")
    }
    
    internal var lastActivityDate: Date {
        get {
            return syncQueue.sync { storedActivityDate }
        }
        set {
            syncQueue.sync { storedActivityDate = newValue }
        }
    }
    
    func startTracking() {
        updateLastActivityDate()
        trackingTimer.start { [weak self] timer in
            guard let strongSelf = self else {
                timer.stop()
                return
            }
            if strongSelf.isTerminationAllowed {
                timer.stop()
                strongSelf.fireHandlers()
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
        guard !isTerminationAllowed else { return }
        lastActivityDate = dateProvider.currentDate()
    }
    
    private func fireHandlers() {
        let handlers = syncQueue.sync { self.handlers }
        for handler in handlers {
            handler()
        }
    }
}
