import Deployer
import Foundation
import PathLib

public protocol SSHClient {
    @discardableResult
    func execute(_ command: [String]) throws -> Int32
    func upload(localPath: AbsolutePath, remotePath: AbsolutePath) throws
}

public struct SSHClientExecutionError: Error, CustomStringConvertible {
    public let command: [String]
    public let exitCode: Int32
    
    public var description: String {
        "Command \(command) finished unsuccessfully with exit code \(exitCode)"
    }
}

extension SSHClient {
    public func executeAndCheckResult(_ command: [String]) throws {
        let exitCode = try execute(command)
        if exitCode != 0 {
            throw SSHClientExecutionError(command: command, exitCode: exitCode)
        }
    }
}
