import Foundation

/**
 Wraps a random Encodable so JSONEncoder may be able to encode a list of `[AnyEncodableWrapper]` as
 it cannot encode a list of `[Encodable]` out of the box.
 */
public class AnyEncodableWrapper: Encodable {
    let instance: Encodable
    
    public init(_ instance: Encodable) {
        self.instance = instance
    }
    
    public func encode(to encoder: Encoder) throws {
        try instance.encode(to: encoder)
    }
}
