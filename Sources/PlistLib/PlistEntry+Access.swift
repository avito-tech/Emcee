import Foundation

public extension PlistEntry {
    
    // MARK: Dict
    
    enum PlistEntryError: CustomStringConvertible, Error {
        case typeMismatch(PlistEntry, expectedType: Any)
        case noObjectForKey(entry: PlistEntry, key: String)
        
        public var description: String {
            switch self {
            case .typeMismatch(let entry, let expectedType):
                return "Plist entry \(entry) type differs from expected type \(expectedType)"
            case .noObjectForKey(let entry, let key):
                return "Entry \(entry) does not have object for key \(key)"
            }
        }
    }
    
    // MARK: Dict
    
    /// Casts this entry to dict entry and extracts its value.
    /// - Throws: Error if this entry is not an dict plist entry.
    /// - Returns: Dictionary of `String` to `PlistEntry` elements.
    func dictEntry() throws -> [String: PlistEntry] {
        try matchType()
    }
    
    /// Casts this entry to dict entry and extracts an optional value for a given key.
    /// - Parameter key: The key which `PlistEntry` should be provided, is present.
    /// - Throws: Error if this entry is not an dict plist entry.
    /// - Returns: `PlistEntry` for a given `key`, or `nil` if no value is present for the given key.
    func optionalEntry(forKey key: String) throws -> PlistEntry? {
        try dictEntry()[key]
    }
    
    /// Casts this entry to dict entry and extracts an expected value for a given key.
    /// - Parameter key: The key which `PlistEntry` should be provided, if present.
    /// - Throws: Error if this entry is not an dict plist entry, or if no value is present for the provided `key`.
    /// - Returns: `PlistEntry` for a given `key`.
    func entry(forKey key: String) throws -> PlistEntry {
        guard let entry = try optionalEntry(forKey: key) else {
            throw PlistEntryError.noObjectForKey(entry: self, key: key)
        }
        return entry
    }
    
    /// Casts this entry to dict entry and extracts the optional values for the given keys.
    /// - Parameter keys: The keys which `PlistEntry` should be provided, if present.
    /// - Throws: Error if this entry is not an dict plist entry.
    /// - Returns: A map from key to its plist entry. If the entry is missing for some given key, no error will be thrown.
    func optionalEntries(forKeys keys: [String]) throws -> [String: PlistEntry] {
        try keys.reduce(into: [String: PlistEntry]()) { (result, key) in
            if let entry = try optionalEntry(forKey: key) {
                result[key] = entry
            }
        }
    }
    
    /// Casts this entry to dict entry and extracts the required values for the given keys.
    /// - Parameter keys: The keys which `PlistEntry` should be provided, if present.
    /// - Throws: Error if this entry is not an dict plist entry, or if entry is missing for any provided key.
    /// - Returns: A map from key to its plist entry. 
    func entries(forKeys keys: [String]) throws -> [String: PlistEntry] {
        try keys.reduce(into: [String: PlistEntry]()) { (result, key) in
            result[key] = try entry(forKey: key)
        }
    }
    
    /// Casts dict entry to a dict whose values are expected to have a single type
    /// - Parameter valueType: Expected type of all values of the dictionary
    /// - Throws: This method throws error if any value can't be casted to the given type
    /// - Returns: Dictionary with string keys and `T` values.
    func toTypedDict<T>(_ valueType: T.Type) throws -> [String: T] {
        try dictEntry().mapValues { try $0.matchType() }
    }
    
    /// Casts this entry to dict entry and returns its keys.
    /// - Throws: Error if this entry is not an dict plist entry.
    /// - Returns: An array of keys of dict entry.
    func allKeys() throws -> [String] {
        Array(try dictEntry().keys.map { String($0) })
    }
    
    // MARK: Array
    
    /// Casts this entry to array and extracts its value.
    /// - Throws: Error if this entry is not an array plist entry.
    /// - Returns: Array of `PlistEntry` elements.
    func arrayEntry() throws -> [PlistEntry] {
        try matchType()
    }
    
    /// Casts this entry to array and provides a `PlistEntry` under a given `index`.
    /// - Throws: Error if this entry is not an array plist entry.
    /// - Returns: `PlistEntry` element under given `index`.
    func entry(atIndex index: Int) throws -> PlistEntry {
        try arrayEntry()[index]
    }
    
    /// Casts array entry to a array whose elements are expected to have a single type `T`.
    /// - Parameter valueType: Expected type of all elements of array
    /// - Throws: This method throws error if any element can't be casted to the given type
    /// - Returns: Array of `T` elements.
    func toTypedArray<T>(_ type: T.Type) throws -> [T] {
        try arrayEntry().compactMap { try $0.matchType() }
    }
    
    // MARK: Leaf Types Supported by Plist
    
    func boolValue() throws -> Bool {
        try matchType()
    }
    
    func stringValue() throws -> String {
        try matchType()
    }
    
    func numberValue() throws -> Double {
        try matchType()
    }
    
    func dateValue() throws -> Date {
        try matchType()
    }
    
    func dataValue() throws -> Data {
        try matchType()
    }
    
    // MARK: Casting to any Type

    /// Casts this plist entry to a given type `T`.
    /// Plist supports a limited set of types: `Array`, `Dictionary` with `String` keys, `Date`, `Data`, `Bool`, `Number` (represented as `Double` here for simplicity), `String`.
    /// Attempt to cast to any other type will likely throw an error.
    /// Note: array and dict entries will return a value with `PlistEntry` objects. Use array and dict specific shortcut methods to cast the whole collection to a desired type instead.
    /// - Throws: `PlistEntryError` if this plist entry type is not castable to `T`.
    /// - Returns: A value casted to `T`.
    func matchType<T>() throws -> T {
        switch self {
        case .array(let value):
            if let value = value as? T { return value }
        case .dict(let value):
            if let value = value as? T { return value }
        case .bool(let value):
            if let value = value as? T { return value }
        case .data(let value):
            if let value = value as? T { return value }
        case .date(let value):
            if let value = value as? T { return value }
        case .number(let value):
            if let value = value as? T { return value }
        case .string(let value):
            if let value = value as? T { return value }
        }

        throw PlistEntryError.typeMismatch(self, expectedType: T.self)
    }
}
