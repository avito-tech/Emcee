import Foundation

public protocol KibanaClient {
    func send(
        level: String,
        message: String,
        metadata: [String: String],
        completion: @escaping (Error?) -> ()
    ) throws
}
