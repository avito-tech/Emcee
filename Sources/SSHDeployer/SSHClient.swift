import Foundation
import Models

public protocol SSHClient {
    init(host: String, port: Int32, username: String, password: String) throws
    func connectAndAuthenticate() throws
    @discardableResult
    func execute(_ command: [String]) throws -> Int32
    func upload(localUrl: URL, remotePath: String) throws
}
