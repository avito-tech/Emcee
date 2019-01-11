import Foundation

public protocol VersionProvider {
    func version() throws -> Version
}
