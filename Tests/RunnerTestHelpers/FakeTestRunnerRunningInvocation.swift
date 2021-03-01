import Foundation
import EmceeLogging
import ProcessController
import Runner
import Tmp

public final class FakeTestRunnerRunningInvocation: TestRunnerRunningInvocation {
    private let tempFolder: TemporaryFolder
    private let uuid = UUID()
    public var onCancel: () -> () = {}
    public var onWait: () -> () = {}
    
    public init(tempFolder: TemporaryFolder) {
        self.tempFolder = tempFolder
    }
    
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
