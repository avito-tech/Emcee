import Foundation
import RunnerModels

public protocol RSTypedValue {
    static var typeName: String { get }
    static var superTypeName: String? { get }
}

extension RSTypedValue {
    public static var superTypeName: String? { nil }
}

public protocol RSNamedValue: RSTypedValue {
    static var name: RSString { get }
}

struct RSType: Codable, ExpressibleByStringLiteral, Equatable {
    let _name: String
    
    typealias StringLiteralType = String
    init(stringLiteral value: String) {
        _name = value
    }
    
    init(_ name: String) {
        _name = name
    }
}

extension RSTypedValue {
    var _type: RSType {
        RSType(Self.typeName)
    }
}

enum _RsTypeKeys: CodingKey {
    case _type
    case name
    case _value
}

extension RSTypedValue {
    static func validateRsType(decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _RsTypeKeys.self)
        let type = try container.decode(RSType.self, forKey: _RsTypeKeys._type)
        do {
            try assertValueMatches(expected: Self.typeName, actual: type._name)
        } catch {
            if let supername = Self.superTypeName {
                try assertValueMatches(expected: supername, actual: type._name)
            } else {
                throw error
            }
        }
    }
}

extension RSNamedValue {
    static func validate(decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: _RsTypeKeys.self)
        
        let name = try container.decode(RSString.self, forKey: _RsTypeKeys.name)
        try assertValueMatches(expected: name.stringValue, actual: Self.name.stringValue)
    }
}

struct ValueMismatchError: Error, CustomStringConvertible {
    let expectedValue: String
    let actualValue: String
    var description: String {
        "Expected to have value \(expectedValue), but found \(actualValue)"
    }
}

func assertValueMatches(expected: String, actual: String) throws {
    guard expected == actual else {
        throw ValueMismatchError(expectedValue: expected, actualValue: actual)
    }
}
