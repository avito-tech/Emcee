import Foundation

public final class DefaultProcessControllerProvider: ProcessControllerProvider {
    public init() {}
    
    public func createProcessController(subprocess: Subprocess) throws -> ProcessController {
        return try DefaultProcessController(subprocess: subprocess)
    }
}
