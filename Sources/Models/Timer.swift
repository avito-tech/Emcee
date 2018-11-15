import Dispatch
import Foundation

public final class Timer {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "ru.avito.emcee.Timer.queue")
    private let repeating: DispatchTimeInterval
    private let leeway: DispatchTimeInterval

    public init(repeating: DispatchTimeInterval, leeway: DispatchTimeInterval) {
        self.repeating = repeating
        self.leeway = leeway
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
