import Foundation

public final class EventArgumentValue: Encodable {
    public let payload: Encodable

    public init(payload: Encodable) {
        self.payload = payload
    }

    public func encode(to encoder: Encoder) throws {
        try payload.encode(to: encoder)
    }
}
