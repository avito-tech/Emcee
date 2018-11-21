import Dispatch
import Foundation

public final class DispatchBasedTimer {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "ru.avito.emcee.Timer.queue")
    private let repeating: DispatchTimeInterval
    private let leeway: DispatchTimeInterval

    public init(repeating: DispatchTimeInterval, leeway: DispatchTimeInterval) {
        self.repeating = repeating
        self.leeway = leeway
    }
    
    public static func startedTimer(
        repeating: DispatchTimeInterval,
        leeway: DispatchTimeInterval,
        handler: @escaping () -> ())
        -> DispatchBasedTimer
    {
        let timer = DispatchBasedTimer(repeating: repeating, leeway: leeway)
        timer.start(handler: handler)
        return timer
    }
    
    deinit {
        stop()
    }
    
    public func start(handler: @escaping () -> ()) {
        stop()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: repeating, leeway: leeway)
        timer.setEventHandler(handler: handler)
        timer.resume()
        self.timer = timer
    }
    
    public func stop() {
        timer?.cancel()
    }
}
