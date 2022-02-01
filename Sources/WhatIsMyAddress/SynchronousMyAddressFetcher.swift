import Foundation

public protocol SynchronousMyAddressFetcher {
    func fetch(timeout: TimeInterval) throws -> String
}
