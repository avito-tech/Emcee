import Dispatch
import Foundation
import Logging

public final class ParentProcessTracker {
    private let queue = DispatchQueue(label: "ru.avito.ParentProcessTracker.queue")
    private var timer: DispatchSourceTimer?
    private let whenParentDies: () -> ()
    private let parentPid: Int32
    
    public enum `Error`: Swift.Error {
        case noParentPidProvided
    }
    
    public static let envName = "AVITO_RUNNER_OUTER_PROCESS_ID"
    
    public init(whenParentDies: @escaping () -> ()) throws {
        self.whenParentDies = whenParentDies
        guard let parentPidValue = ProcessInfo.processInfo.environment[ParentProcessTracker.envName],
            let parentPid = Int32(parentPidValue) else
        {
            throw Error.noParentPidProvided
        }
        self.parentPid = parentPid
        startTracking()
    }
    
    deinit {
        timer?.cancel()
    }
    
    private var parentIsAlive: Bool {
        return kill(parentPid, 0) == 0
    }
    
    private func startTracking() {
        log("Will track parent process aliveness: \(parentPid)")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .seconds(1))
        timer.setEventHandler {
            if !self.parentIsAlive {
                self.whenParentDies()
            }
        }
        timer.resume()
        self.timer = timer
    }
}
