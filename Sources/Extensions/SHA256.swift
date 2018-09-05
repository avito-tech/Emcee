import Foundation

extension Data {
    public func avito_sha256Hash() -> Data {
        let transform = SecDigestTransformCreate(kSecDigestSHA2, 256, nil)
        SecTransformSetAttribute(transform, kSecTransformInputAttributeName, self as CFTypeRef, nil)
        return SecTransformExecute(transform, nil) as! Data
    }
}

extension String {
    public enum AvitoSHA256Error: Error {
        case unableToHash
    }
    
    public func avito_sha256Hash(encoding: String.Encoding = .utf8) throws -> String {
        guard let dataToHash = self.data(using: encoding) else { throw AvitoSHA256Error.unableToHash }
        let hashedData = dataToHash.avito_sha256Hash()
        
        return hashedData.reduce("") { (result, byte) -> String in
            result + String(format:"%02x", UInt8(byte))
        }
    }
}
