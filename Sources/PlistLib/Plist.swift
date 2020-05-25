import Foundation

public final class Plist {
    /// The root plist entry, either an array or a dict.
    public let root: RootPlistEntry
    
    public init(rootPlistEntry: RootPlistEntry) {
        self.root = rootPlistEntry
    }
    
    /// Returns a root object of this plist with all children elements. This can be an `Array` or `Dictionary`.
    /// This object can be serialized to a plist format using `PropertyListSerialization`.
    public func rootObject() -> Any { root.plistEntry.dumpedValue() }
    
    /// Creates a `Plist` obejct from given `Data`.
    public static func create(fromData data: Data) throws -> Plist {
        return Plist(rootPlistEntry: try RootPlistEntry.create(fromData: data))
    }
}

public extension Plist {
    func data(format: PropertyListSerialization.PropertyListFormat) throws -> Data {
        return try PropertyListSerialization.data(
            fromPropertyList: rootObject(),
            format: format,
            options: 0
        )
    }
}

extension RootPlistEntry {
    public enum UnexpectedTypeError: CustomStringConvertible, Error {
        case unexpectedTypeOfRootObject(Any)
        
        public var description: String {
            switch self {
            case .unexpectedTypeOfRootObject(let any):
                return "Unexpected root object: \(any)"
            }
        }
    }
    
    static func create(fromData data: Data, format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>? = nil) throws -> RootPlistEntry {
        let object = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: format
        )
        if let dict = object as? NSDictionary {
            return RootPlistEntry.dict(try PlistEntry.create(dict: dict))
        } else if let array = object as? NSArray {
            return RootPlistEntry.array(try PlistEntry.create(array: array))
        }
        throw UnexpectedTypeError.unexpectedTypeOfRootObject(object)
    }
}

public enum PlistReadError: Error {
    case keyIsNotTypeOfString(actualKey: Any)
    case unrecognizedValue(Any)
}

extension PlistEntry {
    func dumpedValue() -> Any {
        switch self {
        case .array(let values):
            return values.compactMap { $0?.dumpedValue() }
        case .dict(let values):
            return values.compactMapValues { $0?.dumpedValue() }
        case .bool(let value):
            return value
        case .data(let value):
            return value
        case .date(let value):
            return value
        case .number(let value):
            return value
        case .string(let value):
            return value
        }
    }
    
    static func create(dict: NSDictionary) throws -> [String: PlistEntry] {
        return try dict.reduce(into: [String: PlistEntry]()) { (result: inout [String: PlistEntry], keyValue: (key: Any, value: Any)) in
            guard let stringKey = keyValue.key as? String else {
                throw PlistReadError.keyIsNotTypeOfString(actualKey: keyValue.key)
            }
            result[stringKey] = try create(fromAny: keyValue.value)
        }
    }
    
    static func create(array: NSArray) throws -> [PlistEntry] {
        return try array.map { element in
            try create(fromAny: element)
        }
    }
    
    static func create(fromAny any: Any) throws -> PlistEntry {
        if let arrayElement = any as? NSArray {
            return .array(
                try PlistEntry.create(array: arrayElement)
            )
        } else if let dataElement = any as? Data {
            return .data(dataElement)
        } else if let stringElement = any as? String {
            return .string(stringElement)
        } else if let dateElement = any as? Date {
            return .date(dateElement)
        } else if let numberElement = any as? NSNumber {
            if numberElement === kCFBooleanTrue || numberElement === kCFBooleanFalse {
                return .bool(numberElement.boolValue)
            } else {
                return .number(numberElement.doubleValue)
            }
        } else if let dictElement = any as? NSDictionary {
            return .dict(
                try PlistEntry.create(dict: dictElement)
            )
        }
        
        throw PlistReadError.unrecognizedValue(any)
    }
}
