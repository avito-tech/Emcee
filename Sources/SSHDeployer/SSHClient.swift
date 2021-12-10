import Deployer
import Foundation
import PathLib

public protocol SSHClient {
    init(host: String, port: Int32, username: String, authentication: DeploymentDestinationAuthenticationType) throws
    func connectAndAuthenticate() throws
    @discardableResult
    func execute(_ command: [String]) throws -> Int32
    func upload(localPath: AbsolutePath, remotePath: AbsolutePath) throws
}
