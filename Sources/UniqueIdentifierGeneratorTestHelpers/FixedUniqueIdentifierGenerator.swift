import Foundation
import UniqueIdentifierGenerator

public final class FixedUniqueIdentifierGenerator: UniqueIdentifierGenerator {
    public let value: String
    
    public init(value: String = UUID().uuidString) {
        self.value = value
    }
    
    public func generate() -> String {
        return value
    }
}
