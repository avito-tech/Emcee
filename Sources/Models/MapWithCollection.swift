import Foundation

public struct MapWithCollection<Key, ValueElement> where Key : Hashable {
    
    private var dictionary = [Key: [ValueElement]]()
    
    public init(_ dictionary: [Key: [ValueElement]] = [:]) {
        self.dictionary = dictionary
    }
    
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
    
    public var flattenValues: [ValueElement] { values.flatMap { $0 } }
    
    public var asDictionary: [Key: [ValueElement]] { dictionary }
    
    public mutating func append(key: Key, element: ValueElement) {
        append(key: key, elements: [element])
    }
    
    public mutating func append(key: Key, elements: [ValueElement]) {
        self[key] = self[key] + elements
    }
    
    public mutating func removeValue(forKey key: Key) {
        dictionary.removeValue(forKey: key)
    }
    
    public var isEmpty: Bool { dictionary.isEmpty }
    
    public var count: Int { dictionary.count }
    
    public mutating func extend(_ other: MapWithCollection<Key, ValueElement>) {
        for keyValue in other.asDictionary {
            append(key: keyValue.key, elements: keyValue.value)
        }
    }
}

extension MapWithCollection: ExpressibleByDictionaryLiteral {
    public typealias Key = Key
    public typealias Value = [ValueElement]
    
    public init(dictionaryLiteral elements: (Key, [ValueElement])...) {
        self = MapWithCollection()
        for element in elements {
            append(key: element.0, elements: element.1)
        }
    }
}

extension MapWithCollection: Decodable where Key: Decodable, ValueElement: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = MapWithCollection(
            try container.decode([Key: [ValueElement]].self)
        )
    }
}

extension MapWithCollection: Encodable where Key: Encodable, ValueElement: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dictionary)
    }
}

extension MapWithCollection: Equatable where Key: Equatable, ValueElement: Equatable {
    
}
