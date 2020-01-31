import Foundation
import ProcessController

public final class FakeProcessControllerProvider: ProcessControllerProvider {
    public var creator: (Subprocess) throws -> (ProcessController)
    
    public init(creator: @escaping (Subprocess) throws -> ProcessController = { FakeProcessController(subprocess: $0)}) {
        self.creator = creator
    }
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        return try creator(subprocess)
    }
}
