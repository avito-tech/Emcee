import Foundation
import Logging
import ProcessController
import Runner
import TemporaryStuff

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
    
    public var output: StandardStreamsCaptureConfig {
        StandardStreamsCaptureConfig(
            stdoutPath: try? tempFolder.createFile(filename: "\(uuid)_stdout.log"),
            stderrPath: try? tempFolder.createFile(filename: "\(uuid)_stderr.log")
        )
    }
    
    public var subprocessInfo: SubprocessInfo {
        SubprocessInfo(subprocessId: 42, subprocessName: "fake process")
    }
    
    public func wait() {
        onWait()
    }
}
