import Dispatch
import Foundation
import Models
import Signals
import Types

public typealias SignalHandler = (Int32) -> ()

private let syncQueue = DispatchQueue(label: "ru.avito.emcee.SignalHandling")
private var signalHandlers = MapWithCollection<Int32, SignalHandler>()

public final class SignalHandling {
    private init() {}
    
    /// Captures and holds a given handler and invokes it when any provided signal occurs.
    public static func addSignalHandler(signals: Set<Signal>, handler: @escaping SignalHandler) {
        for signal in signals {
            addSignalHandler(signal: signal, handler: handler)
        }
    }
    
    /// Captures and holds a given handler and invokes it when a required signal occurs.
    public static func addSignalHandler(signal: Signal, handler: @escaping SignalHandler) {
        syncQueue.sync {
            signalHandlers.append(key: signal.intValue, element: handler)
        }
        
        Signals.trap(signal: signal.blueSignal) { signalValue in
            _handleSignal(signalValue)
        }
    }
}

/// Universal signal handler
private func _handleSignal(_ signalValue: Int32) {
    let registeredHandlers = syncQueue.sync { signalHandlers[signalValue] }
    for handler in registeredHandlers {
        handler(signalValue)
    }
}
