import Foundation

public struct MapWithCollection<Key, ValueElement> where Key : Hashable {
    
    private var dictionary = [Key: [ValueElement]]()
    
    public init() {}
    
    public subscript(key: Key) -> [ValueElement] {
        set {
            if newValue.isEmpty {
                dictionary.removeValue(forKey: key)
            } else {
                dictionary[key] = newValue
            }
        }
        get {
            return dictionary[key] ?? []
        }
    }
    
    public var values: [[ValueElement]] {
        return Array(dictionary.values)
    }
    
    public mutating func append(key: Key, element: ValueElement) {
        append(key: key, elements: [element])
    }
    
    public mutating func append(key: Key, elements: [ValueElement]) {
        self[key] = self[key] + elements
    }
    
    public mutating func removeValue(forKey key: Key) {
        dictionary.removeValue(forKey: key)
    }
}
