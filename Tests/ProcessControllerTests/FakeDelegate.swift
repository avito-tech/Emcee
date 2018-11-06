import Foundation
import ProcessController

final class FakeDelegate: ProcessControllerDelegate {
    var stdout = Data()
    var stderr = Data()
    var noActivityDetected = false
    let stream: Bool
    
    public init(stream: Bool = false) {
        self.stream = stream
    }
    
    func processController(_ sender: ProcessController, newStdoutData data: Data) {
        if stream, let string = String(data: data, encoding: .utf8) {
            print("stdout: \(string)")
        }
        stdout.append(data)
    }
    
    func processController(_ sender: ProcessController, newStderrData data: Data) {
        if stream, let string = String(data: data, encoding: .utf8) {
            print("stderr: \(string)")
        }
        stderr.append(data)
    }
    
    func processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(_ sender: ProcessController) {
        noActivityDetected = true
        sender.interruptAndForceKillIfNeeded()
    }
}
