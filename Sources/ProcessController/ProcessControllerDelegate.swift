import Foundation

public protocol ProcessControllerDelegate: class {
    func processController(_ sender: ProcessController, newStdoutData data: Data)
    func processController(_ sender: ProcessController, newStderrData data: Data)
    func processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(_ sender: ProcessController)
}
