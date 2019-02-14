import Foundation

public enum DSNError: Error, CustomStringConvertible {
    case envIsNotSet(String)
    case incorrectValue(String)
    case missingPublicKey
    case missingPrivateKey
    case unableToConstructStoreUrl(String)
    
    public var description: String {
        switch self {
        case .envIsNotSet(let env):
            return "Cannot take DSN from environment: env.\(env) is not set"
        case .incorrectValue(let value):
            return "Incorrect DSN string provided: '\(value)'"
        case .missingPublicKey:
            return "Missing DSN public key"
        case .missingPrivateKey:
            return "Missing DSN private key"
        case .unableToConstructStoreUrl(let value):
            return "Cannot build store URL from '\(value)'"
        }
    }
}
