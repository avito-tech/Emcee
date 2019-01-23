import AutomaticTermination
import Foundation
import QueueServer

public final class AutomaticTerminationControllerAwareQueueServerLock: QueueServerLock {
    private let automaticTerminationController: AutomaticTerminationController

    public init(automaticTerminationController: AutomaticTerminationController) {
        self.automaticTerminationController = automaticTerminationController
    }
    
    public var isDiscoverable: Bool {
        return !automaticTerminationController.isTerminationAllowed
    }
}
