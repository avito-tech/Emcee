import Foundation
import Models
import RequestSender

public final class FakeRequestSender: RequestSender {
    
    public var result: Any?
    public var requestSenderError: RequestSenderError?

    public init(result: Any?, requestSenderError: RequestSenderError?) {
        self.result = result
        self.requestSenderError = requestSenderError
    }

    public func sendRequestWithCallback<Payload, Response>(
        pathWithSlash: String,
        payload: Payload,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<Response, RequestSenderError>) -> ()
    ) where Payload : Encodable, Response : Decodable {
        if let result = result {
            callbackQueue.async { callback(Either.left(result as! Response)) }
        } else if let requestSenderError = requestSenderError {
            callbackQueue.async { callback(Either.right(requestSenderError)) }
        }
    }
    
    public var isClosed = false
    
    public func close() {
        isClosed = true
    }
}
