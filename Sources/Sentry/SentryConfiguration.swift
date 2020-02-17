import Foundation

public struct SentryConfiguration: Codable, Equatable {
    public let dsn: URL

    public init(dsn: URL) {
        self.dsn = dsn
    }
}
