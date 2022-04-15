import Dispatch
import Foundation
import EmceeLogging
import Types

public protocol RequestSender {
    func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        credentials: Credentials?,
        callbackQueue: DispatchQueue,
        logFailedRequest: Bool,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    )
    
    func close()
}

extension RequestSender {
    public func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        callbackQueue: DispatchQueue,
        logFailedRequest: Bool = true,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    ) {
        self.sendRequestWithCallback(
            request: request,
            credentials: nil,
            callbackQueue: callbackQueue,
            logFailedRequest: logFailedRequest,
            callback: callback
        )
    }
}
