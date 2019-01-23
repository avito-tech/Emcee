import BalancingBucketQueue
import Foundation

public enum WorkerAlivenessPolicy {
    case workersStayAliveWhenQueueIsDepleted
    case workersTerminateWhenQueueIsDepleted
    
    public func nothingToDequeueBehavior(checkLaterInterval: TimeInterval) -> NothingToDequeueBehavior {
        switch self {
        case .workersStayAliveWhenQueueIsDepleted:
            return NothingToDequeueBehaviorCheckLater(checkAfter: checkLaterInterval)
        case .workersTerminateWhenQueueIsDepleted:
            return NothingToDequeueBehaviorWaitForAllQueuesToDeplete(checkAfter: checkLaterInterval)
        }
    }
}

