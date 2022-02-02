import Foundation
import EmceeLogging
import EmceeLoggingModels
import ProcessController
import Runner

public final class FakeTestRunnerRunningInvocation: TestRunnerRunningInvocation {
    public var onCancel: () -> () = {}
    public var onWait: () -> () = {}
    
    public init() {}
    
    public func cancel() {
        onCancel()
    }
    
    public var pidInfo: PidInfo {
        PidInfo(pid: 42, name: "fake process")
    }
    
    public func wait() {
        onWait()
    }
}
