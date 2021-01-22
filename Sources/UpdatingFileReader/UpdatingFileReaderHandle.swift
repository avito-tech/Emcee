import Foundation
import ProcessController

public protocol UpdatingFileReaderHandle {
    func cancel()
}

public final class ProcessUpdatingFileReaderHandle: UpdatingFileReaderHandle {
    private let processController: ProcessController
    
    public init(processController: ProcessController) {
        self.processController = processController
    }
    
    public func cancel() {
        processController.interruptAndForceKillIfNeeded()
    }
}
