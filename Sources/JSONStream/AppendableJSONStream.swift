import Foundation

public protocol AppendableJSONStream: JSONStream {
    func append(bytes: [UInt8])
}

public extension AppendableJSONStream {
    func append(data: Data) {
        let bytes = [UInt8](data)
        append(bytes: bytes)
    }
    
    func append(string: String) {
        append(bytes: Array(string.utf8))
    }
}
