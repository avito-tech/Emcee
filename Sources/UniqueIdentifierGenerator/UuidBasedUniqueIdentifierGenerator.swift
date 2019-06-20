import Foundation

public final class UuidBasedUniqueIdentifierGenerator: UniqueIdentifierGenerator {
    public init() {}
    
    public func generate() -> String {
        return UUID().uuidString
    }
}
