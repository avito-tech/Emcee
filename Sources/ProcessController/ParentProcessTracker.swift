import Dispatch
import Foundation
import Logging
import Timer

public final class ParentProcessTracker {
    private var timer: DispatchBasedTimer?
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
    
    private var parentIsAlive: Bool {
        return kill(parentPid, 0) == 0
    }
    
    private func startTracking() {
        Logger.debug("Will track parent process aliveness: \(parentPid)")
        self.timer = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) {
            if !self.parentIsAlive {
                self.whenParentDies()
            }
        }
    }
}
