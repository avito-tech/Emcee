import Dispatch
import Extensions
import Foundation
import Logging
import Models

public protocol RequestSender {
    func sendRequestWithCallback<Payload, Response>(
        pathWithSlash: String,
        payload: Payload,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<Response, RequestSenderError>) -> ()
    ) where Payload : Encodable, Response : Decodable
    
    func close()
}
