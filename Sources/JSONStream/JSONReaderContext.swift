import Foundation

final class NumericStorage {
    let string = NSMutableString()
    var parsedNumber: NSNumber?
    
    public init(_ initialString: String?) {
        if let initialString = initialString {
            string.append(initialString)
        }
    }
}

enum ParsingContext: CustomStringConvertible {
    case root
    case inObject(key: String?, storage: NSMutableDictionary)
    case inArray(key: String?, storage: NSMutableArray)
    case inKey(NSMutableString)
    case inValue(key: String)
    case inStringObject(storage: NSMutableString)
    case inStringValue(key: String?, storage: NSMutableString)
    case inNullValue(key: String?)
    case inTrueValue(key: String?)
    case inFalseValue(key: String?)
    case inNumericValue(key: String?, storage: NumericStorage)
    
    var description: String {
        switch self {
        case .root:
            return "root"
        case .inObject(let key, let storage):
            return "inObject for key '\(key ?? "null")': '\(storage)'"
        case .inArray(let key, let storage):
            return "inArray for key '\(key ?? "null")': '\(storage)'"
        case .inKey(let key):
            return "inKey \(key)"
        case .inValue(let key):
            return "inValue for key '\(key)'"
        case .inStringValue(let key, let storage):
            return "inStringValue for key '\(key ?? "null")': '\(storage)'"
        case .inStringObject(let storage):
            return "inStringObject: '\(storage)'"
        case .inNullValue(let key):
            return "inNullValue for key '\(key ?? "null")'"
        case .inTrueValue(let key):
            return "inTrueValue for key '\(key ?? "null")'"
        case .inFalseValue(let key):
            return "inFalseValue for key '\(key ?? "null")'"
        case .inNumericValue(let key, let storage):
            return "inNumericValue for key '\(key ?? "null")': '\(storage)'"
        }
    }
}
