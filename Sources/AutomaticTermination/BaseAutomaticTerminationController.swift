import AtomicModels
import DateProvider
import Dispatch
import Foundation
import EmceeLogging
import Timer

internal class BaseAutomaticTerminationController: AutomaticTerminationController {
    internal let dateProvider: DateProvider
    let lastActivityDate: AtomicValue<Date>
    private let handlers = AtomicValue<[AutomaticTerminationControllerHandler]>([])
    private var trackingTimer = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(1))
    
    init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
        lastActivityDate = AtomicValue(dateProvider.currentDate())
    }
    
    var isTerminationAllowed: Bool {
        fatalError("Subclasses must override this method")
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
        handlers.withExclusiveAccess {
            $0.append(handler)
        }
    }
    
    func indicateActivityFinished() {
        updateLastActivityDate()
    }
    
    private func updateLastActivityDate()  {
        guard !isTerminationAllowed else { return }
        lastActivityDate.set(dateProvider.currentDate())
    }
    
    private func fireHandlers() {
        for handler in handlers.currentValue() {
            handler()
        }
    }
}
