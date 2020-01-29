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

    public var request: Any?
    public var credentials: Credentials?
    public func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        credentials: Credentials?,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    ) {
        self.request = request
        self.credentials = credentials

        if let result = result {
            callbackQueue.async { callback(Either.left(result as! NetworkRequestType.Response)) }
        } else if let requestSenderError = requestSenderError {
            callbackQueue.async { callback(Either.right(requestSenderError)) }
        }
    }
    
    public var isClosed = false
    
    public func close() {
        isClosed = true
    }
}
