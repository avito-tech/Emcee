import Extensions
import Foundation
import Logging
import Models

public final class RequestSenderImpl: RequestSender {
    private let encoder = JSONEncoder.pretty()
    private let urlSession: URLSession
    private let queueServerAddress: SocketAddress
    private var isClosed = false

    public init(urlSession: URLSession, queueServerAddress: SocketAddress) {
        self.urlSession = urlSession
        self.queueServerAddress = queueServerAddress
    }
    
    public func close() {
        Logger.verboseDebug("Invalidating URL session")
        urlSession.finishTasksAndInvalidate()
        isClosed = true
    }
    
    public func sendRequestWithCallback<Payload, Response>(
        pathWithSlash: String,
        payload: Payload,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<Response, RequestSenderError>) -> ()
    ) where Payload : Encodable, Response : Decodable {
        do {
            try sendRequest(
                pathWithSlash: pathWithSlash,
                payload: payload,
                callbackQueue: callbackQueue,
                callback: callback
            )
        } catch {
            callbackQueue.async {
                callback(.error(.cannotIssueRequest(error)))
            }
        }
    }
    
    private func sendRequest<Payload, Response>(
        pathWithSlash: String,
        payload: Payload,
        callbackQueue: DispatchQueue,
        callback: @escaping (Either<Response, RequestSenderError>) -> ()
    ) throws where Payload : Encodable, Response : Decodable {
        let url = try createUrl(pathWithSlash: pathWithSlash)
        
        guard !isClosed else {
            throw RequestSenderError.sessionIsClosed(url)
        }
        
        let jsonData = try encoder.encode(payload)
        if let stringJson = String(data: jsonData, encoding: .utf8) {
            Logger.verboseDebug("Sending request to \(url): \(stringJson)")
        } else {
            Logger.verboseDebug("Sending request to \(url): unable to get string for json data \(jsonData.count) bytes")
        }
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: .infinity)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Content-Type", forHTTPHeaderField: "application/json")
        urlRequest.httpBody = jsonData
        let dataTask = urlSession.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                Logger.verboseDebug("Failed to perform request to \(url): \(error)")
                callbackQueue.async { callback(.error(.communicationError(error))) }
            } else if let data = data {
                do {
                    let decodedObject = try JSONDecoder().decode(Response.self, from: data)
                    Logger.verboseDebug("Successfully decoded object from response of request to \(url): \(decodedObject)")
                    callbackQueue.async { callback(.success(decodedObject)) }
                } catch {
                    Logger.verboseDebug("Failed to decode object from response of request to \(url): \(error)")
                    callbackQueue.async { callback(.error(.parseError(error, data))) }
                }
            } else {
                Logger.verboseDebug("Failed to perform request to \(url): response has no data")
                callbackQueue.async { callback(.error(.noData)) }
            }
        }
        dataTask.resume()
    }
    
    private func createUrl(pathWithSlash: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = queueServerAddress.host
        components.port = queueServerAddress.port
        components.path = pathWithSlash
        guard let url = components.url else {
            throw RequestSenderError.unableToCreateUrl(components)
        }
        return url
    }
}
