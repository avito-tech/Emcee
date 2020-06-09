import Foundation
import PathLib

public final class StandardStreamsCaptureConfig: CustomStringConvertible {
    public let stdoutContentsFile: AbsolutePath
    public let stderrContentsFile: AbsolutePath

    public init(
        stdoutContentsFile: AbsolutePath? = nil,
        stderrContentsFile: AbsolutePath? = nil
    ) {
        let uuid = UUID().uuidString
        self.stdoutContentsFile = stdoutContentsFile ?? AbsolutePath(NSTemporaryDirectory()).appending(component: "\(uuid)_stdout.log")
        self.stderrContentsFile = stderrContentsFile ?? AbsolutePath(NSTemporaryDirectory()).appending(component: "\(uuid)_stderr.log")
    }
    
    public var description: String {
        return "<stdout: \(stdoutContentsFile), stderr: \(stderrContentsFile)>"
    }
}
