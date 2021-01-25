import Foundation
import ProcessController

public protocol ObservableFileReaderHandler {
    func cancel()
}

public final class ProcessObservableFileReaderHandler: ObservableFileReaderHandler {
    private let processController: ProcessController
    
    public init(processController: ProcessController) {
        self.processController = processController
    }
    
    public func cancel() {
        processController.interruptAndForceKillIfNeeded()
    }
}
