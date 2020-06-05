import Foundation
import Logging
import ProcessController
import Runner

public final class FakeTestRunnerRunningInvocation: TestRunnerRunningInvocation {
    public var cancelled = false
    
    public func cancel() {
        cancelled = true
    }
    
    public var output: StandardStreamsCaptureConfig {
        StandardStreamsCaptureConfig()
    }
    
    public var subprocessInfo: SubprocessInfo {
        SubprocessInfo(subprocessId: 42, subprocessName: "fake process")
    }
    
    public func wait() {}
}
