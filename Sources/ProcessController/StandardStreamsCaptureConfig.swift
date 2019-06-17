import Foundation

public final class StandardStreamsCaptureConfig {
    public let stdoutContentsFile: String
    public let stderrContentsFile: String
    public let stdinContentsFile: String

    public init(
        stdoutContentsFile: String? = nil,
        stderrContentsFile: String? = nil,
        stdinContentsFile: String? = nil
    ) {
        let uuid = UUID().uuidString
        self.stdoutContentsFile = stdoutContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_stdout.log")
        self.stderrContentsFile = stderrContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_stderr.log")
        self.stdinContentsFile = stdinContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_stdin.log")
    }
}
