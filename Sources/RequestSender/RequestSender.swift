import Dispatch
import Foundation
import Logging
import Types

public protocol RequestSender {
    func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        credentials: Credentials?,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    )

    func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    )
    
    func close()
}

extension RequestSender {
    public func sendRequestWithCallback<NetworkRequestType: NetworkRequest>(
        request: NetworkRequestType,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<NetworkRequestType.Response, RequestSenderError>) -> ()
    ) {
        self.sendRequestWithCallback(
            request: request,
            credentials: nil,
            callbackQueue: callbackQueue,
            callback: callback
        )
    }
}
