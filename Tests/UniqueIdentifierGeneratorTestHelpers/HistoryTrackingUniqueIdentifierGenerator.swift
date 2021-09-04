import Foundation
import UniqueIdentifierGenerator

public class HistoryTrackingUniqueIdentifierGenerator: UniqueIdentifierGenerator {
    public var history = [String]()
    public var delegate: UniqueIdentifierGenerator
    
    public init(delegate: UniqueIdentifierGenerator) {
        self.delegate = delegate
    }
    
    public func generate() -> String {
        let result = delegate.generate()
        history.append(result)
        return result
    }
}
