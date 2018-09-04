import Foundation

class NumberValidator {
    private static let unsupportedCharacterSet = CharacterSet(charactersIn: "-+0123456789eE.").inverted
    private static let exponentialSeparator = CharacterSet(charactersIn: "eE")
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    enum `Error`: Swift.Error {
        case invalidNumber(String)
        case invalidIntPart(String)
        case invalidFractionalPart(String)
        case invalidExponentialPart(String)
    }
    
    static func validateStringRepresentationOfNumber(_ string: String) throws -> NSNumber {
        guard string.rangeOfCharacter(from: unsupportedCharacterSet) == nil else { throw Error.invalidNumber(string) }
        
        let parts = string.components(separatedBy: ".")
        
        if parts.count == 1 {
            let intAndExponentialParts = parts[0].components(separatedBy: exponentialSeparator)
            try validateIntPartOfNumber(intAndExponentialParts[0])
            if intAndExponentialParts.count == 2 {
                try validateExponentialPartOfNumber(intAndExponentialParts[1])
            } else if intAndExponentialParts.count > 2 {
                throw Error.invalidNumber(string)
            }
        } else if parts.count == 2 {
            try validateIntPartOfNumber(parts[0])
            let fractionalAndExponentialParts = parts[1].components(separatedBy: exponentialSeparator)
            try validateFractionalPartOfNumber(fractionalAndExponentialParts[0])
            if fractionalAndExponentialParts.count == 2 {
                try validateExponentialPartOfNumber(fractionalAndExponentialParts[1])
            } else if fractionalAndExponentialParts.count > 2 {
                throw Error.invalidNumber(string)
            }
        } else {
            throw Error.invalidNumber(string)
        }
        
        if let number = numberFormatter.number(from: string) {
            return number
        } else {
            throw Error.invalidNumber(string)
        }
    }
    
    static func validateIntPartOfNumber(_ string: String) throws {
        var intPart = string
        if intPart.starts(with: "-") { intPart.removeFirst() }
        guard intPart.rangeOfCharacter(from: CharacterSet(charactersIn: "+eE")) == nil else { throw Error.invalidIntPart(string) }
        guard intPart.count > 0 else { throw Error.invalidIntPart(string) }
        if intPart.contains("+") { throw Error.invalidIntPart(string) }
        if intPart.starts(with: "0") && intPart.count > 1 { throw Error.invalidIntPart(string) }
    }
    
    static func validateFractionalPartOfNumber(_ fractionalPart: String) throws {
        guard fractionalPart.count > 0 else { throw Error.invalidFractionalPart(fractionalPart) }
    }
    
    static func validateExponentialPartOfNumber(_ exponentialPart: String) throws {
        guard exponentialPart.count > 0 else { throw Error.invalidExponentialPart(exponentialPart) }
    }
}
