import Foundation
import RequestSender
import Types

open class FakeRequestSender: RequestSender {
    
    public var result: Any?
    public var requestSenderError: RequestSenderError?
        
    /// Use this to validate request in tests, and set `result` or `requestSenderError` depending on validation results.
    public var validateRequest: (FakeRequestSender) -> () = { _ in }
    
    /// Called after `callbackQueue` processes `callback` made by this request sender.
    /// This may be used as a kind of an indication that request has finished its work.
    /// Note: `callback` may start some asynchronous work and that likely won't be finished by the moment when `requestCompleted` will be executing.
    public var requestCompleted: (FakeRequestSender) -> ()

    public init(
        result: Any? = nil,
        requestSenderError: RequestSenderError? = nil,
        requestCompleted: @escaping (FakeRequestSender) -> () = { _ in }
    ) {
        self.result = result
        self.requestSenderError = requestSenderError
        self.requestCompleted = requestCompleted
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
        
        validateRequest(self)

        if let result = result {
            callbackQueue.async { callback(Either.left(result as! NetworkRequestType.Response)) }
        } else if let requestSenderError = requestSenderError {
            callbackQueue.async { callback(Either.right(requestSenderError)) }
        }
        
        callbackQueue.async(flags: .barrier) {
            self.requestCompleted(self)
        }
    }
    
    public var isClosed = false
    
    public func close() {
        isClosed = true
    }
}
