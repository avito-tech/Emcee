import Foundation

public class FakeKibanaClient: KibanaClient {
    public init() {}
    
    public struct Payload {
        public let level: String
        public let message: String
        public let metadata: [String : String]
        public let completion: (Error?) -> ()
    }
    
    public var onSend: (Payload) throws -> () = { _ in }
    public var capturedEvents = [Payload]()
    
    public func send(level: String, message: String, metadata: [String : String], completion: @escaping (Error?) -> ()) throws {
        let payload = Payload(
            level: level,
            message: message,
            metadata: metadata,
            completion: completion
        )
        capturedEvents.append(payload)
        try onSend(payload)
    }
}
