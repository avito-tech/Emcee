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
    
    public mutating func append(key: Key, element: ValueElement) {
        let elements = self[key]
        self[key] = elements + [element]
    }
    
    public mutating func removeValue(forKey key: Key) {
        dictionary.removeValue(forKey: key)
    }
}
