import Foundation

public protocol ProcessControllerProvider {
    func createProcessController(subprocess: Subprocess) throws -> ProcessController
}
