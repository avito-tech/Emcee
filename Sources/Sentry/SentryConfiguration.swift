import Foundation

public struct SentryConfiguration: Codable, Hashable {
    public let dsn: URL

    public init(dsn: URL) {
        self.dsn = dsn
    }
}
