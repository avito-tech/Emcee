import Foundation

public struct ExplainingError: Error, CustomStringConvertible {
    public let context: String?
    public let key: String?
    public let error: Error
    public var description: String {
        var result = "Failed to decode"
        if let key = key {
            result += " value for key \"\(key)\""
        }
        if key != nil, context != nil {
            result += " in"
        }
        if let context = context {
            result += " \"\(context)\""
        }
        result += ": \(error)"
        
        return result
    }
}

extension JSONDecoder {
    public func decodeExplaining<T>(
        _ type: T.Type,
        from data: Data,
        context: String? = nil
    ) throws -> T where T : Decodable {
        do {
            return try decode(type, from: data)
        } catch {
            throw ExplainingError(context: context, key: nil, error: error)
        }
    }
}

extension DecodingError: CustomStringConvertible {
    public var decodingContext: DecodingError.Context {
        switch self {
        case .typeMismatch(_, let context):
            return context
        case .valueNotFound(_, let context):
            return context
        case .keyNotFound(_, let context):
            return context
        case .dataCorrupted(let context):
            return context
        @unknown default:
            fatalError("Unknown case value. See \(#file):\(#line).")
        }
    }
    
    public var description: String {
        var contextString: String = ""
        if !decodingContext.codingPath.isEmpty {
            contextString = " at: " + String(decodingContext.codingPath.map {
                if let index = $0.intValue {
                    return "[\(index)]"
                }
                return "." + $0.stringValue
            }.joined().dropFirst())
        }
        
        switch self {
        case .typeMismatch:
            return "type mismatch\(contextString)"
        case .valueNotFound:
            return "missing value\(contextString)"
        case .keyNotFound(let key, _):
            return "key \"\(key.stringValue)\" not found\(contextString)"
        case .dataCorrupted:
            return "data is corrupted\(contextString)"
        @unknown default:
            fatalError("Unknown case value. See \(#file):\(#line).")
        }
    }
}

extension KeyedDecodingContainer {
    public func decodeExplaining<T>(
        _ type: T.Type,
        forKey key: KeyedDecodingContainer<K>.Key,
        context: String? = nil
    ) throws -> T where T : Decodable {
        do {
            return try decode(type, forKey: key)
        } catch {
            throw ExplainingError(context: context, key: key.stringValue, error: error)
        }
    }
    
    public func decodeIfPresentExplaining<T>(
        _ type: T.Type,
        forKey key: KeyedDecodingContainer<K>.Key,
        context: String? = nil
    ) throws -> T? where T : Decodable {
        do {
            return try decodeIfPresent(type, forKey: key)
        } catch {
            throw ExplainingError(context: context, key: key.stringValue, error: error)
        }
    }
}
