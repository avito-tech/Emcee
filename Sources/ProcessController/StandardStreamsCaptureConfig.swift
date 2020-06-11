import Foundation
import PathLib

public final class StandardStreamsCaptureConfig: CustomStringConvertible {
    private let stdoutPath: AbsolutePath?
    private let stderrPath: AbsolutePath?

    public init(
        stdoutPath: AbsolutePath? = nil,
        stderrPath: AbsolutePath? = nil
    ) {
        self.stdoutPath = stdoutPath
        self.stderrPath = stderrPath
    }
    
    public var description: String {
        let stdout = stdoutPath?.pathString ?? "null"
        let stderr = stderrPath?.pathString ?? "null"
        return "<stdout: \(stdout), stderr: \(stderr)>"
    }
    
    public enum PathIsNotSetError: Error, CustomStringConvertible {
        case stdoutPathNotSet
        case stderrPathNotSet
        
        public var description: String {
            switch self {
            case .stderrPathNotSet:
                return "Stderr file path for output is not set. Use config from running process instance."
            case .stdoutPathNotSet:
                return "Stdout file path for output is not set. Use config from running process instance."
            }
        }
    }
    
    public func stdoutOutputPath() throws -> AbsolutePath {
        guard let path = stdoutPath else { throw PathIsNotSetError.stdoutPathNotSet }
        return path
    }
    
    public func stderrOutputPath() throws -> AbsolutePath {
        guard let path = stderrPath else { throw PathIsNotSetError.stderrPathNotSet }
        return path
    }
}

extension StandardStreamsCaptureConfig {
    func byRedefiningIfNotSet(stdoutOutputPath: AbsolutePath, stderrOutputPath: AbsolutePath) -> StandardStreamsCaptureConfig {
        StandardStreamsCaptureConfig(
            stdoutPath: stdoutPath ?? stdoutOutputPath,
            stderrPath: stderrPath ?? stderrOutputPath
        )
    }
}
