import Extensions
import Foundation
import Logging
import Models

public protocol RequestSender {
    func sendRequestWithCallback<Payload, Response>(
        pathWithSlash: String,
        payload: Payload,
        callback: @escaping (Either<Response, RequestSenderError>) -> ()
    ) throws where Payload : Encodable, Response : Decodable
    
    func close()
}
