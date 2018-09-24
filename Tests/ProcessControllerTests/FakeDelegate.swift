import Foundation
import ProcessController

final class FakeDelegate: ProcessControllerDelegate {
    var stdout = Data()
    var stderr = Data()
    var noActivityDetected = false
    
    public init() {}
    
    func processController(_ sender: ProcessController, newStdoutData data: Data) {
        stdout.append(data)
    }
    
    func processController(_ sender: ProcessController, newStderrData data: Data) {
        stderr.append(data)
    }
    
    func processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(_ sender: ProcessController) {
        noActivityDetected = true
        sender.interruptAndForceKillIfNeeded()
    }
}
